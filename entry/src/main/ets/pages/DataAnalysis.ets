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
  BarDataSet,
  BarChartModel,
  BarData,
  IBarDataSet,
  BarEntry,
  BarChart,
} from '@ohos/mpchart';
import { InputMethodListDialog } from '@ohos.inputMethodList';
import HorizontalViewPortHandler from '@ohos/mpchart/src/main/ets/components/utils/HorizontalViewPortHandler';

import { AIChatBot } from 'ets/http/Large_model'; // <-- 确保路径正确
import { router } from '@kit.ArkUI';

interface ChatMessage{
  content:string;//消息内容
  isUser:boolean;//消息是否发送
}


@Entry
@Component
struct DataAnalysis{

  // 使用 @State 装饰器声明 LineChartModel 实例，@State 会让UI在 model 变化时刷新
  @State lineChartModel: LineChartModel = new LineChartModel();
  @State barChartModel: BarChartModel = new BarChartModel();

  // 用于存储聊天消息列表
  @State chatMessages: ChatMessage[] = [];
  // 用于存储输入框当前的文本内容
  @State inputText: string = '';

  @State message: string = ""; // 直接用单个字符串状态




  // aboutToAppear 生命周期钩子：组件即将显示时调用，适合在此准备数据和初始化模型
  aboutToAppear() {
    // console.log("DataAnalysis aboutToAppear: Initializing line chart."); // 调试日志
    this.initLineChart();
    // console.log("DataAnalysis aboutToAppear: Line chart initialized."); // 调试日志
    this.initBarChart();  // 初始化柱状图
  }

  // 初始化折线图模型，配置数据和样式 (包含两条线)
  initLineChart() {
    // === 第一条线数据：例如，传感器数据 (蓝色) ===
    let entries1: JArrayList<EntryOhos> = new JArrayList<EntryOhos>();
    for (let i = 0; i < 12; i++) {
      // 随机生成 y 值，范围 [10, 60]
      let yValue = Math.random() * 50 + 10;
      entries1.add(new EntryOhos(i, yValue));
    }
    // console.log(`Generated ${entries1.size()} entries for Line 1.`); // 调试日志

    // 创建并配置第一个 LineDataSet
    let lineDataSet1 = new LineDataSet(entries1, "传感器温度"); // 第一个图例标签
    lineDataSet1.getColor(Color.Blue);          // 设置线条颜色为蓝色 (可以直接使用 Color.Blue 或 hex 值 0xFF0000FF)
    lineDataSet1.setCircleColor(Color.Blue);    // 数据点圆圈颜色
    lineDataSet1.setLineWidth(2);               // 线条宽度
    lineDataSet1.setCircleRadius(4);            // 数据点圆圈半径
    lineDataSet1.setDrawValues(false);          // 通常第一条线也不绘制值，保持简洁
    lineDataSet1.setMode(Mode.CUBIC_BEZIER);     // 平滑曲线


    // === 第二条线数据：例如，另一个传感器数据 或 对比数据 (红色) ===
    let entries2: JArrayList<EntryOhos> = new JArrayList<EntryOhos>();
    for (let i = 0; i < 12; i++) {
      // 随机生成 y 值，范围 [20, 70]，与第一条数据有所区分
      let yValue = Math.random() * 50 + 20;
      entries2.add(new EntryOhos(i, yValue));
    }
    // console.log(`Generated ${entries2.size()} entries for Line 2.`); // 调试日志

    // 创建并配置第二个 LineDataSet
    let lineDataSet2 = new LineDataSet(entries2, "传感器湿度"); // 第二个图例标签，需要有区别
    lineDataSet2.getColor(Color.Red);          // 设置线条颜色为红色 (可以直接使用 Color.Red 或 hex 值 0xFFFF0000)
    lineDataSet2.setCircleColor(Color.Red);    // 数据点圆圈颜色
    lineDataSet2.setLineWidth(2);              // 线条宽度 (可以和第一条线相同或不同)
    lineDataSet2.setCircleRadius(4);           // 数据点圆圈半径
    lineDataSet2.setDrawValues(false);         // 不绘制数据点的值
    lineDataSet2.setMode(Mode.LINEAR);         // 第二条线使用直线连接模式 (Mode.LINEAR) 作为对比 (可选)
    // 可以设置其他样式，例如：
    // lineDataSet2.enableDashedLine(10, 5, 0); // 虚线效果


    // 3. 组装数据集
    // 创建一个 JArrayList 来存放所有 LineDataSet
    let dataSets: JArrayList<ILineDataSet> = new JArrayList<ILineDataSet>();
    dataSets.add(lineDataSet1); // 添加第一个 DataSet
    dataSets.add(lineDataSet2); // 添加第二个 DataSet

    // 创建 LineData 对象，包含所有 DataSet
    let lineData = new LineData(dataSets);

    // 将 LineData 设置到 ChartModel 中
    this.lineChartModel.setData(lineData);
    // console.log("LineData set to model."); // 调试日志


    // 4. 配置 X 轴
    // X轴配置通常适用于整个图表，所有数据集共用一个X轴
    let xAxis = this.lineChartModel.getXAxis();
    if (xAxis) {
      xAxis.setPosition(XAxisPosition.BOTTOM);
      xAxis.setDrawGridLines(false);
      // X轴标签格式化等，可以根据实际数据索引配置显示时间或类别名称
      // xAxis.setValueFormatter(...)
      xAxis.setTextColor(0xFF000000); // X轴文本颜色
      xAxis.setTextSize(10);
    }
    // console.log("XAxis configured."); // 调试日志


    // 5. 配置左侧 Y 轴
    // Y轴配置也适用于整个图表
    let leftAxis = this.lineChartModel.getAxisLeft();
    if (leftAxis) {
      leftAxis.setDrawGridLines(true);
      leftAxis.setAxisMinimum(0); // Y 轴最小值
      // 根据两组数据的范围，可能需要调整 Y 轴最大值，以包含所有数据点
      leftAxis.setAxisMaximum(80); // 例如，如果数据范围最大接近70，设置80比较安全
      leftAxis.setTextColor(0xFF000000); // Y轴文本颜色
      leftAxis.setTextSize(10);
    }
    // console.log("LeftAxis configured."); // 调试日志


    // 6. 禁用右侧 Y 轴 (如果不需要)
    let rightAxis = this.lineChartModel.getAxisRight();
    if (rightAxis) {
      rightAxis.setEnabled(false);
    }
    // console.log("RightAxis configured."); // 调试日志


    // 7. 配置图例 (Legend)，现在会显示两个数据集的标签和颜色块/线
    let legend = this.lineChartModel.getLegend();
    if (legend) {
      legend.setEnabled(true); // 启用图例
      legend.setForm(LegendForm.LINE); // 图例形状为线，对应折线图
      legend.setTextColor(0xFF000000);
      legend.setTextSize(12);
      // 可以根据需要设置图例位置和方向
      // legend.setHorizontalAlignment(LegendHorizontalAlignment.CENTER);
      // legend.setVerticalAlignment(LegendVerticalAlignment.TOP);
      // legend.setOrientation(LegendOrientation.HORIZONTAL);
    }
    // console.log("Legend configured."); // 调试日志


    // 8. 图表描述信息
    let description = new Description();
    description.setText(""); // 更新描述信息
    description.setTextColor(0xFF888888);
    description.setTextSize(10);
    // description.setPosition(...) // 可以设置位置
    this.lineChartModel.setDescription(description);
    // console.log("Description configured."); // 调试日志


    // 9. 启用触摸交互与缩放 (可选)
    this.lineChartModel.setTouchEnabled(true);
    this.lineChartModel.setDragEnabled(true);
    this.lineChartModel.setScaleEnabled(true);
    this.lineChartModel.setPinchZoom(true);
    // console.log("Touch/Scale configured."); // 调试日志


    // 10. === 核心：添加折线图展开动画 ===
    // 这个动画应用到加载到模型中的所有数据上
    this.lineChartModel.animateX(1500); // 1.5秒的从左到右动画
    // console.log("animateX(1500) called."); // 调试日志


    // 11. 刷新视图
    // 通知绑定模型的 LineChart 组件进行重绘
    this.lineChartModel.invalidate();
    // console.log("invalidate() called."); // 调试日志
  }

  // === 柱状图初始化函数 (基本保留我给你的逻辑) ===
  initBarChart() {
    // === 第一组柱子数据：例如，当月销售额 (蓝色) ===
    let entries1: JArrayList<BarEntry> = new JArrayList<BarEntry>();
    for (let i = 0; i < 12; i++) {
      let yValue = Math.random() * 4000 + 1000;
      entries1.add(new BarEntry(i, yValue));
    }
    let barDataSet1 = new BarDataSet(entries1, "传感器温度");
    barDataSet1.setColorByColor(Color.Blue); // 蓝色
    barDataSet1.setDrawValues(false);

    // === 第二组柱子数据：例如，上月销售额 (红色) ===
    let entries2: JArrayList<BarEntry> = new JArrayList<BarEntry>();
    for (let i = 0; i < 12; i++) {
      let yValue = Math.random() * 3700 + 800;
      entries2.add(new BarEntry(i, yValue));
    }
    let barDataSet2 = new BarDataSet(entries2, "传感器湿度");
    barDataSet2.setColorByColor(Color.Red); // 红色
    barDataSet2.setDrawValues(false);

    // 组装数据集并配置分组
    let barDataSets: JArrayList<IBarDataSet> = new JArrayList<IBarDataSet>();
    barDataSets.add(barDataSet1);
    barDataSets.add(barDataSet2);
    let barData = new BarData(barDataSets);

    let groupSpace = 0.3;
    let barWidth = 0.35;
    let barSpace = 0.0;
    barData.setBarWidth(barWidth);
    barData.groupBars(0, groupSpace, barSpace);

    // 设置数据到柱状图模型
    this.barChartModel.setData(barData);

    // 配置柱状图的 X 轴
    let barXAxis = this.barChartModel.getXAxis();
    if (barXAxis) {
      barXAxis.setPosition(XAxisPosition.BOTTOM);
      barXAxis.setDrawGridLines(false);
      barXAxis.setGranularity(1);
      barXAxis.setCenterAxisLabels(true); // 重要：标签居中
      barXAxis.setTextColor(0xFF000000);
      barXAxis.setTextSize(10);
      barXAxis.setGranularityEnabled(true);
    }

    // 配置柱状图的 左 Y 轴
    let barLeftAxis = this.barChartModel.getAxisLeft();
    if (barLeftAxis) {
      barLeftAxis.setDrawGridLines(true);
      barLeftAxis.setAxisMinimum(0);
      barLeftAxis.setAxisMaximum(6000); // 适当调整
      barLeftAxis.setTextColor(0xFF000000);
      barLeftAxis.setTextSize(10);
      barLeftAxis.setAxisMinimum(0);
    }

    // 禁用柱状图的 右 Y 轴
    let barRightAxis = this.barChartModel.getAxisRight();
    if (barRightAxis) {
      barRightAxis.setEnabled(false);
    }

    // 配置柱状图的图例
    let barLegend = this.barChartModel.getLegend();
    if (barLegend) {
      barLegend.setEnabled(true);
      barLegend.setForm(LegendForm.SQUARE); // 方形图例
      barLegend.setTextColor(0xFF000000);
      barLegend.setTextSize(12);
    }

    // 配置柱状图的描述信息
    let barDescription = new Description();
    barDescription.setText("");
    barDescription.setTextColor(0xFF888888);
    barDescription.setTextSize(10);
    this.barChartModel.setDescription(barDescription);

    // 启用柱状图触摸交互
    this.barChartModel.setTouchEnabled(true);
    this.barChartModel.setDragEnabled(true);
    this.barChartModel.setScaleEnabled(true);
    this.barChartModel.setPinchZoom(true);

    // 柱状图动画
    this.barChartModel.animateY(1500);

    // 通知柱状图刷新
    this.barChartModel.invalidate();
  }



  build() {
    Column(){
      Column(){
        Button("退出")
          .onClick(()=>{
            router.replaceUrl({
              url:'pages/Analysis'
            })
          })
      }
      .width("100%")
      .margin({left:20})
      .alignItems(HorizontalAlign.Start)

      Column(){
        Row(){
          Image($r("app.media.graph"))
            .width(30)
            .objectFit(ImageFit.Contain)
            .margin({left:5})

          Text("数据图")
            .fontSize(16)
            .margin({left:10})
        }
      }
      .width("100%")
      .alignItems(HorizontalAlign.Start)

      Column(){
        LineChart({model: this.lineChartModel})
          .width("100%")
          .height("100%")
      }
      .width("100%")
      .height(200)
      .padding(10)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .margin({left:16,right:16,bottom:10})

      Column(){
        Row(){
          Image($r("app.media.histogram"))
            .width(30)
            .margin({left:5})
            .objectFit(ImageFit.Contain)

          Text("数据图")
            .fontSize(16)
            .margin({left:10})
        }
      }
      .width("100%")
      .alignItems(HorizontalAlign.Start)

      Column(){
        BarChart({model:this.barChartModel})

          .width("100%")
          .height("100%")
      }
      .width("100%")
      .height(200)
      .padding(10)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .margin({left:16,right:16,bottom:10})


      Column() {
        // 聊天消息显示区域，可滚动
        Scroll() {
          Column() {
            ForEach(this.chatMessages, (msg: ChatMessage) => {
              Row() {
                if (msg.isUser) {
                  // 用户消息样式
                  Text(msg.content)
                    .fontSize(14)
                    .fontColor('#000')
                    .padding(8)
                    .margin(4)
                    .backgroundColor('#DCF8C6') // 用户消息背景色
                } else {
                  // AI 消息样式
                  Row() {
                    Image($r('app.media.deepseek')) // AI 图标，确保路径正确
                      .width(30)
                      .height(30)
                      .objectFit(ImageFit.Contain)
                    Text(msg.content)
                      .fontSize(14)
                      .fontColor('#000')
                      .width("90%")
                      .padding(8)
                      .margin(4)
                      .backgroundColor('#FFFFFF') // AI 消息背景色
                  }
                }
              }
              .width('100%')
              .justifyContent(msg.isUser ? FlexAlign.End : FlexAlign.Start) // 用户消息靠右，AI 消息靠左
            }, (msg: ChatMessage) => msg.content)
          }
          .width("100%")
        }
        .width('100%')
        .layoutWeight(1)

        // 用户输入区域
        Row() {
          TextInput({ placeholder: '输入你的问题...' })
            .width('80%')
            .height(40)
            .padding(8)
            .fontSize(14)
            .onChange((value) => {
              this.inputText = value; // 更新输入框内容
            })

          Button('发送')
            .width('20%')
            .height(40)
            .margin({ left: 8 })
            .onClick(() => {
              if (this.inputText.trim() === '') return; // 空消息不发送

              // 添加用户消息到聊天记录
              this.chatMessages.push({ content: this.inputText, isUser: true });

              // 调用 AIChatBot API 获取回答
              AIChatBot.queryAPI(this.inputText).then((answer) => {
                if (answer) {
                  // 添加 AI 回答到聊天记录
                  this.chatMessages.push({ content: answer, isUser: false });
                } else {
                  // 处理 API 返回 null 的情况
                  this.chatMessages.push({ content: '抱歉，无法获取回答。', isUser: false });
                }
              });

              // 清空输入框
              this.inputText = '';
            })
        }
        .width('100%')
        .height(50)
        .padding(8)
      }
      .width('100%')
      .height(210)
    }
    .height("100%")
    .width("100%")
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor("#E8E8E8")
  }
}
