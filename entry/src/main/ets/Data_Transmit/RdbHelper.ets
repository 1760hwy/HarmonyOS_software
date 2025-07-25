// src/main/ets/common/RdbHelper.ts
// 【最新官方API版本】

import { relationalStore } from '@kit.ArkData';
import type common from '@ohos.app.ability.common';
import type { BusinessError } from '@kit.BasicServicesKit';
import { SensorData } from './SensorDataAbility';

const DB_NAME = "sensor_data.db";//数据库名
const TABLE_NAME = "sensor_records";//表名
const DB_VERSION = 1; // 定义我们的目标数据库版本

// 创建表的SQL语句
const CREATE_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    temperature REAL NOT NULL,
    humidity REAL NOT NULL,
    lightIntensity REAL NOT NULL,
    timestamp INTEGER NOT NULL
  )
`;

//数据库帮助类
export class RdbHelper {
  private rdbStore: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;
  private context: common.UIAbilityContext;

  //构造函数接收UIAC上下文
  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  // 核心：初始化数据库。它将回调风格的 API 包装成 Promise
  private initialize(): Promise<void> {
    if (!this.initPromise) {
      this.initPromise = new Promise((resolve, reject) => {
        //配置数据库信息
        const config: relationalStore.StoreConfig = {
          name: DB_NAME,
          securityLevel: relationalStore.SecurityLevel.S1//安全等级为S1
        };

        //获取RDB实例
        relationalStore.getRdbStore(this.context, config, (err, store) => {
          if (err) {
            console.error(`RDB: Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
            reject(err);
            return;
          }

          console.info('RDB: Succeeded in getting RdbStore.');
          this.rdbStore = store;

          // 手动进行版本管理
          try {
            // 1. 首次创建 (数据库版本为0)
            if (store.version === 0) {
              console.info('RDB: Database is new, creating table...');
              store.executeSql(CREATE_TABLE_SQL);//执行建表语句
              store.version = DB_VERSION; // 设置为目标版本
              console.info(`RDB: Database version set to ${DB_VERSION}`);
            }
            // 2. 升级 (当前版本低于目标版本)
            else if (store.version < DB_VERSION) {
              console.warn(`RDB: Upgrading database from ${store.version} to ${DB_VERSION}`);
              // 在这里添加你的升级逻辑, 例如:
              // if (store.version === 1) { store.executeSql('ALTER ...'); }
              // if (store.version === 2) { store.executeSql('ALTER ...'); }
              // 简单起见，我们直接删表重建
              store.executeSql(`DROP TABLE IF EXISTS ${TABLE_NAME}`);
              store.executeSql(CREATE_TABLE_SQL);
              store.version = DB_VERSION;
              console.info(`RDB: Database upgraded and version set to ${DB_VERSION}`);
            }
            resolve();
          } catch (e) {
            const error = e as BusinessError;
            console.error(`RDB: Failed to create/upgrade table. Code:${error.code}, message:${error.message}`);
            reject(error);
          }
        });
      });
    }
    return this.initPromise;
  }

  // 获取RDB Store实例，确保已初始化
  private async getStore(): Promise<relationalStore.RdbStore> {
    await this.initialize();
    if (!this.rdbStore) {
      throw new Error("RDB store initialization failed.");
    }
    return this.rdbStore;
  }

  // 插入数据 (现在可以使用 async/await 了)
  async insertData(data: SensorData): Promise<number> {
    const store = await this.getStore();
    const value: relationalStore.ValuesBucket = {
      temperature: data.temperature,
      humidity: data.humidity,
      lightIntensity: data.lightIntensity,
      timestamp: data.timestamp
    };
    const rowId = await store.insert(TABLE_NAME, value);

    // 插入成功后，执行数据清理逻辑
    await this.trimRecords();

    return rowId;
  }

  // 查询所有数据
  async queryAllData(): Promise<SensorData[]> {
    const store = await this.getStore();
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.orderByDesc("timestamp");

    const resultSet = await store.query(predicates);
    const results: SensorData[] = [];
    try {
      while (resultSet.goToNextRow()) {
        const record = new SensorData(0, 0, 0);
        record.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        record.temperature = resultSet.getDouble(resultSet.getColumnIndex('temperature'));
        record.humidity = resultSet.getDouble(resultSet.getColumnIndex('humidity'));
        record.lightIntensity = resultSet.getDouble(resultSet.getColumnIndex('lightIntensity'));
        record.timestamp = resultSet.getLong(resultSet.getColumnIndex('timestamp'));
        results.push(record);
      }
    } finally {
      resultSet.close(); // 确保结果集被关闭
    }
    return results;
  }

  // 删除数据
  async deleteData(id: number): Promise<number> {
    const store = await this.getStore();
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo("id", id);
    return store.delete(predicates);
  }

  // 更新数据
  async updateData(data: SensorData): Promise<number> {
    if (!data.id) return 0;
    const store = await this.getStore();
    let predicates = new relationalStore.RdbPredicates(TABLE_NAME);
    predicates.equalTo("id", data.id);
    const value: relationalStore.ValuesBucket = {
      temperature: data.temperature,
      humidity: data.humidity,
      lightIntensity: data.lightIntensity,
    };
    return store.update(value, predicates);
  }
  // 【新增】: 清理记录的辅助方法
  private async trimRecords(): Promise<void> {
    const MAX_RECORDS = 1000; // 设定最大记录数
    try {
      const store = await this.getStore();
      const count = await this.getRecordCount(store);

      // 如果记录数超过上限，则删除最老的一条
      if (count > MAX_RECORDS) {
        console.log(`RDB: Record count (${count}) exceeds limit (${MAX_RECORDS}). Deleting oldest record.`);
        await this.deleteOldestRecord(store);
      }
    } catch(e) {
      console.error('RDB: Failed to trim records.', e);
    }
  }
  // 【修改】: 使用原生 SQL 查询来获取记录总数
  private async getRecordCount(store: relationalStore.RdbStore): Promise<number> {
    const sql = `SELECT COUNT(*) FROM ${TABLE_NAME}`;
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      // 使用 querySql 方法执行原生SQL
      resultSet = await store.querySql(sql);
      if (resultSet.goToFirstRow()) {
        // COUNT(*) 的结果在第一列 (索引为 0)
        return resultSet.getLong(0);
      }
      return 0; // 如果没有记录，返回0
    } finally {
      resultSet?.close(); // 务必关闭结果集
    }
  }

  // 【修改】: 使用原生 SQL 来删除最老的一条记录
  private async deleteOldestRecord(store: relationalStore.RdbStore): Promise<void> {
    // SQLite 支持 'ORDER BY' 和 'LIMIT' 子句直接用在 DELETE 语句中
    // 这条SQL语句的意思是：按id升序排序，然后删除符合条件的第一条记录
    const sql = `
    DELETE FROM ${TABLE_NAME}
    WHERE id IN (
      SELECT id FROM ${TABLE_NAME}
      ORDER BY id ASC
      LIMIT 1
    )`;
    await store.executeSql(sql);
  }
}