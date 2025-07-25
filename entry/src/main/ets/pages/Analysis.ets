import { router } from '@kit.ArkUI'
import {
  JArrayList,                 // 工具类：数据集合
  XAxis,
  XAxisPosition,
  YAxis,
  Description,
  Legend,
  EntryOhos,
  LineDataSet,
  ILineDataSet,
  LineData,
  Mode,
  LineChart,
  LineChartModel,
  LegendForm,
} from '@ohos/mpchart';
import { RdbHelper } from '../Data_Transmit/RdbHelper';
import { SensorData } from '../Data_Transmit/SensorDataAbility';
import common from '@ohos.app.ability.common';

@Entry
@Component
struct Analysis {

  @State selectedIndex1:number=2//下层导航栏默认选中管理平台

  @State lineChartModel: LineChartModel = new LineChartModel();

  // 【第2步：添加新的状态变量和 RdbHelper 实例】
  @State sensorRecords: SensorData[] = [];
  @State isLoading: boolean = true;
  private rdbHelper: RdbHelper | null = null;
  private context: common.UIAbilityContext | null = null;

  aboutToAppear() {
    this.initLineChart();

    this.context = getContext(this) as common.UIAbilityContext;
    if (this.context) {
      this.rdbHelper = new RdbHelper(this.context);
      this.loadDataFromDb();
    } else {
      console.error('Analysis.ts: Failed to get context');
      this.isLoading = false;
    }
  }

  // 新增一个从数据库加载数据的方法
  async loadDataFromDb() {
    this.isLoading = true;
    if (!this.rdbHelper) return;
    try {
      const data = await this.rdbHelper.queryAllData();
      this.sensorRecords = data; // 将查询到的数据赋值给状态变量
    } catch(e) {
      console.error('Analysis.ts: Failed to load data from DB.', e);
    } finally {
      this.isLoading = false;
    }
  }

  initLineChart() {
    // 1. 构造数据
    let entries: JArrayList<EntryOhos> = new JArrayList<EntryOhos>();
    for (let i = 0; i < 12; i++) {
      // 随机生成 y 值，范围 [10, 60]
      let yValue = Math.random() * 50 + 10;
      entries.add(new EntryOhos(i, yValue));
    }

    // 2. 创建并配置 LineDataSet
    let lineDataSet = new LineDataSet(entries, "传感器数据");
    // 注意：这里用 setColor(...)，而不是 setLineColor(...)
    lineDataSet.getColor(0xFF0000FF);         // 不透明蓝色
    lineDataSet.setLineWidth(2);
    lineDataSet.setDrawCircles(true);
    lineDataSet.setCircleColor(0xFF0000FF);   // 数据点圆圈颜色
    lineDataSet.setCircleRadius(4);
    lineDataSet.setDrawValues(true);
    lineDataSet.setValueTextColor(0xFF000000); // 不透明黑色
    lineDataSet.setValueTextSize(10);
    lineDataSet.setMode(Mode.CUBIC_BEZIER);    // 平滑曲线

    // 3. 组装数据集
    let dataSets: JArrayList<ILineDataSet> = new JArrayList<ILineDataSet>();
    dataSets.add(lineDataSet);

    let lineData = new LineData(dataSets);
    this.lineChartModel.setData(lineData);

    // 4. 配置 X 轴
    let xAxis = this.lineChartModel.getXAxis();
    if (xAxis) {
      xAxis.setPosition(XAxisPosition.BOTTOM);
      xAxis.setDrawGridLines(false);
      // 如果想要自定义刻度间隔：xAxis.setGranularity(1);
      // 也可设置标签格式化：xAxis.setValueFormatter(...)
    }

    // 5. 配置左侧 Y 轴
    let leftAxis = this.lineChartModel.getAxisLeft();
    if (leftAxis) {
      leftAxis.setDrawGridLines(true);
      leftAxis.setAxisMinimum(0); // Y 轴最小值
    }

    // 6. 禁用右侧 Y 轴
    let rightAxis = this.lineChartModel.getAxisRight();
    if (rightAxis) {
      rightAxis.setEnabled(false);
    }

    // 7. 配置图例 (Legend)
    let legend = this.lineChartModel.getLegend();
    if (legend) {
      legend.setEnabled(true);
      legend.setForm(LegendForm.LINE);
      legend.setTextColor(0xFF000000);
    }

    // 8. 图表描述信息
    let description = new Description();
    description.setText("最近12小时数据变化");
    description.setTextColor(0xFF888888);
    this.lineChartModel.setDescription(description);

    // 9. 启用触摸交互与缩放
    this.lineChartModel.setTouchEnabled(true);
    this.lineChartModel.setDragEnabled(true);
    this.lineChartModel.setScaleEnabled(true);
    this.lineChartModel.setPinchZoom(true);

    // 10. 刷新
    this.lineChartModel.invalidate();
  }

  build() {
    Stack() {
      Column() {
        Text("当前位置:湖南省株洲市")
          .fontSize(20)
          .margin({ top: 10, bottom: 5, left: 16 })
          .width("100%")

        Row() {
          Button("AI数据分析")
            .onClick(()=>{
              router.replaceUrl({
                url:'pages/DataAnalysis'
              });
            })
        }
        .justifyContent(FlexAlign.End)
        .margin({ right: 10 })
        .width("100%")

        // 中间图表区域
        Column() {
          Row() {
            Image($r("app.media.graph"))
              .objectFit(ImageFit.Contain)//图片适配(完全显示图片)
              .width(30)

            // 标题
            Text("数据图")
              .fontSize(16)
              .margin({ left: 10 })
          }
          .justifyContent(FlexAlign.Start)
          .margin({ left: 10 })
          .alignItems(VerticalAlign.Center)
          .width("100%")

          // 使用 LineChart
          Column() {
            LineChart({ model: this.lineChartModel })
              .width('100%')
              .height('100%')
          }
          .height(230)
          .padding(10)

          Column() {
            Row() {
              Image($r("app.media.data"))
                .objectFit(ImageFit.Contain)
                .width(30)
              Text("数据库")
                .fontSize(16)
                .margin({ left: 10 })
            }
            .justifyContent(FlexAlign.Start)
            .margin({ left: 10, bottom: 0 }) // 添加 bottom: 10，减小标题与表格的间距
            .alignItems(VerticalAlign.Center)
            .width("100%")

            Stack({alignContent: Alignment.Center}) {
              // Scroll 包裹动态表格
              Scroll() {
                Column() {
                  // 表头 (保持不变)
                  Row() {
                    Text("时间").fontSize(16).fontWeight("bold").padding(8).layoutWeight(1.2);
                    Text("温度").fontSize(16).fontWeight("bold").padding(8).layoutWeight(1);
                    Text("湿度").fontSize(16).fontWeight("bold").padding(8).layoutWeight(1);
                    Text("光照").fontSize(16).fontWeight("bold").padding(8).layoutWeight(1);
                    // 注意：数据库中没有土壤肥力，所以我们在这里不显示它，以保证数据真实性
                    // Text("土壤肥力").fontSize(16).fontWeight("bold").padding(8).layoutWeight(1);
                  }
                  .backgroundColor("#DDDDDD")

                  // 动态数据行区域
                  ForEach(this.sensorRecords, (item: SensorData, index: number) => {
                    Row() {
                      // 将时间戳转换为 时:分:秒 格式
                      Text(new Date(item.timestamp).toLocaleTimeString())
                        .padding(8).layoutWeight(1.2)
                      // 温度
                      Text(`${item.temperature.toFixed(1)}℃`)
                        .padding(8).layoutWeight(1)
                      // 湿度
                      Text(`${item.humidity.toFixed(1)}%`)
                        .padding(8).layoutWeight(1)
                      // 光照
                      Text(`${item.lightIntensity.toFixed(0)}lux`)
                        .padding(8).layoutWeight(1)
                      // 土壤肥力占位
                      // Text("").padding(8).layoutWeight(1); // 如果想保持5列对齐
                    }
                    .backgroundColor(index % 2 === 0 ? Color.White : '#f8f8f8') // 隔行变色
                  })
                }
              }
              .backgroundColor("#FFFFFF")
              .border({ width: 1, color: "#DDDDDD" })
              .padding(8)
              .margin({ left: 8, right: 8, bottom: 8 })
              .visibility(this.isLoading ? Visibility.Hidden : Visibility.Visible) // 加载时隐藏

              // 加载动画
              if (this.isLoading) {
                // 【核心修改】将 Circular 修改为 Ring
                Progress({
                  type: ProgressType.Ring,
                  value: 0
                })
                  .width(50)
                  .color(Color.Blue)
              }

              // 空状态提示
              if (!this.isLoading && this.sensorRecords.length === 0) {
                Text('数据库中没有数据哦').fontColor(Color.Gray).padding(20)
              }
            }
            .layoutWeight(1)
            .padding({ left:10,right:10 })
          }
          .layoutWeight(1) // 让数据库表格部分占据剩余空间
        }
      }
      .width("100%")
      .height("100%")
      .padding({ bottom: 80 }) // 稍微调整，避免和导航栏重叠太紧

      // 底部导航栏
      Row() {
        Column() {
          Image($r("app.media.manage"))
            .objectFit(ImageFit.Contain)
            .width(50)
            .height(35)
          Text("管理平台")
            .fontSize(18)
            .foregroundColor(this.selectedIndex1===0?"#66C241":"#000000")  // 直接设置颜色值

        }
        .onClick(()=>{
          router.replaceUrl({
            url:"pages/Manager"
          })
        })

        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)

        Column() {
          Image($r("app.media.control"))
            .objectFit(ImageFit.Contain)
            .width(50)
            .height(35)
          Text("设备控制")
            .fontSize(18)
            .foregroundColor(this.selectedIndex1===1?"#66C241":"#000000")  // 直接设置颜色值
        }
        .onClick(()=>{
          router.replaceUrl({
            url:"pages/Control"
          });
        })
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)

        Column() {
          Image($r("app.media.analysis"))
            .objectFit(ImageFit.Contain)
            .width(50)
            .height(35)
          Text("数据分析")
            .fontSize(18)
            .foregroundColor(this.selectedIndex1===2?"#66C241":"#000000")  // 直接设置颜色值

        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .justifyContent(FlexAlign.Center)

        Column() {
          Image($r("app.media.my"))
            .width(50)
            .height(35)
            .objectFit(ImageFit.Contain)
          Text("我的")
            .fontSize(18)
            .foregroundColor(this.selectedIndex1===3?"#66C241":"#000000")  // 直接设置颜色值
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)//android:orientation="horizontal"
        .justifyContent(FlexAlign.Center)//android:gravity="center"
        .onClick(()=>{
          router.replaceUrl({
            url:"pages/Myname"
          })
        })
      }
      .width("100%")
      .height(30)
      .border({ width: { top: 1 }, color: '#e0e0e0' }) // 给导航栏顶部加个分割线
      .backgroundColor(Color.White)
      .position({ left: 0, right: 0, bottom: 0 })
    }
    .width('100%')
    .backgroundColor("#E8E8E8")
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .height('100%')
  }
}
