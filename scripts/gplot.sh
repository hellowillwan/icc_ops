#!/usr/bin/gnuplot44
#
# 此脚本使用 gnuplot 绘制 ab 测试结果,不同并发下的请求延时
#
# 参考:
# http://www.cnblogs.com/xoray007/p/3658271.html
# http://stackoverflow.com/questions/5929104/apache-bench-gnuplot-output-what-are-the-column-definitions
# Here is what I have deduced:
#	ctime: Connection Time
#	dtime: Processing Time
#	ttime: Total Time
#	wait: Waiting Time
#
# 测试数据来自:
# ab -X 10.0.0.10:8081 -t 150 -c 10 -n 1000000000 -g ab_inc_icc_mongod_c_10_gnuplot.data 'http://icctesting.umaman.com/inc_icc_mongod.php'
# ab -X 10.0.0.10:8081 -t 150 -c 20 -n 1000000000 -g ab_inc_icc_mongod_c_20_gnuplot.data 'http://icctesting.umaman.com/inc_icc_mongod.php'
# ab -X 10.0.0.10:8081 -t 150 -c 30 -n 1000000000 -g ab_inc_icc_mongod_c_30_gnuplot.data 'http://icctesting.umaman.com/inc_icc_mongod.php'
#

# 设定输出图片的格式
set terminal png         # gnuplot recommends setting terminal before output

# 设定输出的图片文件名
set output "output.png"  # The output filename; to be set after setting

# 设定图表标题
set title "ab -t 150 -c 10/20/30 php-5.6.9 inc_icc_mongod.php"

# X轴标题  
set xlabel "request"

# Y轴标题  
set ylabel "response time (ms)"

# 设定图表的X轴和Y轴缩放比例(相当于调整图片的纵横比例)  
set size 1,0.7

# 设定以Y轴数据为基准绘制栅格(就是示例图表中的横向虚线)
set grid y

#
# 设定plot的数据文件，曲线风格和图例名称，以第九列数据ttime为基准数据绘图  

# plot "ab_500_100.dat" using 9 smooth sbezier with lines title "conc per 100",
#
# "ab_500_200.dat" using 9 smooth sbezier with lines title "conc per 200",
#
# "ab_500_300.dat" using 9 smooth sbezier with lines title "conc per 300" 

plot "ab_inc_icc_mongod_c_10_gnuplot.data" using 9 smooth sbezier with lines title "Concurrency 10", \
     "ab_inc_icc_mongod_c_20_gnuplot.data" using 9 smooth sbezier with lines title "Concurrency 20", \
     "ab_inc_icc_mongod_c_30_gnuplot.data" using 9 smooth sbezier with lines title "Concurrency 30"
