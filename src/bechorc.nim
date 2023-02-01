import asynchttpserver, asyncdispatch, strutils, json, tables, streams

# about 135 MB of live data:
var sessions: Table[string, JsonNode]
for i in 0 ..< 10:
  sessions[$i] = parseJson(newFileStream("data-1.0.json", fmRead), "data-1.0.json")

var served = 0

var server = newAsyncHttpServer()
proc cb(req: Request) {.async.} =
  inc served
  await req.respond(Http200, "Hello World")
  if served mod 10 == 0:
    when not defined(memForSpeed):
      GC_fullCollect()
      
waitFor server.serve(Port(8080), cb)

# nim c -d:release --gc:refc bechorc.nim
# nim c -d:release --gc:arc bechorc.nim
# nim c -d:release --gc:orc bechorc.nim
#debug: refc:646k, arc:659k, orc:701kb
#release: refc:312k, arc:266k, orc:266kb


# wrk -t6 -c100 -d30s --latency http://localhost:8080
# systemctl status bechorc
# mac：活动监视器
 


# 使用方法: wrk <选项> <被测HTTP服务的URL>                            
#   Options:                                            
#     -c, --connections <N>  跟服务器建立并保持的TCP连接数量  
#     -d, --duration    <T>  压测时间           
#     -t, --threads     <N>  使用多少个线程进行压测   
                                                      
#     -s, --script      <S>  指定Lua脚本路径       
#     -H, --header      <H>  为每一个HTTP请求添加HTTP头      
#         --latency          在压测结束后，打印延迟统计信息   
#         --timeout     <T>  超时时间     
#     -v, --version          打印正在使用的wrk的详细版本信息
                                                      
#   <N>代表数字参数，支持国际单位 (1k, 1M, 1G)
#   <T>代表时间参数，支持时间单位 (2s, 2m, 2h)

# 结果
# Running 30s test @ http://www.baidu.com （压测时间30s）
#   12 threads and 400 connections （共12个测试线程，400个连接）
# 			  （平均值） （标准差）  （最大值）（正负一个标准差所占比例）
#   Thread Stats   Avg      Stdev     Max   +/- Stdev
#     （延迟）
#     Latency   386.32ms  380.75ms   2.00s    86.66%
#     (每秒请求数)
#     Req/Sec    17.06     13.91   252.00     87.89%
#   Latency Distribution （延迟分布）
#      50%  218.31ms
#      75%  520.60ms
#      90%  955.08ms
#      99%    1.93s 
#   4922 requests in 30.06s, 73.86MB read (30.06s内处理了4922个请求，耗费流量73.86MB)
#   Socket errors: connect 0, read 0, write 0, timeout 311 (发生错误数)
# Requests/sec:    163.76 (QPS 163.76,即平均每秒处理请求数为163.76)
# Transfer/sec:      2.46MB (平均每秒流量2.46MB)

# arc
# wrk -t6 -c100 -d30s --latency http://localhost:8080
# Running 30s test @ http://localhost:8080
#   6 threads and 100 connections
#   Thread Stats   Avg      Stdev     Max   +/- Stdev
#     Latency     5.06ms    2.07ms 124.28ms   97.48%
#     Req/Sec     3.20k   202.08     4.44k    83.22%
#   Latency Distribution
#      50%    4.73ms
#      75%    5.17ms
#      90%    5.98ms
#      99%    7.86ms
#   574363 requests in 30.03s, 27.39MB read
# Requests/sec:  19125.00
# Transfer/sec:      0.91MB


# refc
#  wrk -t6 -c100 -d30s --latency http://localhost:8080
# Running 30s test @ http://localhost:8080
#   6 threads and 100 connections
#   Thread Stats   Avg      Stdev     Max   +/- Stdev
#     Latency     2.77ms    1.36ms  16.61ms   96.48%
#     Req/Sec    77.05    192.01   742.00     89.47%
#   Latency Distribution
#      50%    2.56ms
#      75%    2.97ms
#      90%    3.38ms
#      99%   10.89ms
#   609 requests in 30.04s, 29.74KB read
#   Socket errors: connect 0, read 0, write 0, timeout 126
# Requests/sec:     20.27
# Transfer/sec:      0.99KB


# ORC 结果
# wrk -t6 -c100 -d30s --latency http://localhost:8080
# Running 30s test @ http://localhost:8080
#   6 threads and 100 connections
#   Thread Stats   Avg      Stdev     Max   +/- Stdev
#     Latency    17.78ms   12.39ms 302.35ms   60.72%
#     Req/Sec     0.92k   120.77     2.18k    68.78%
#   Latency Distribution
#      50%   25.34ms
#      75%   26.08ms
#      90%   26.74ms
#      99%   30.36ms
#   164270 requests in 30.06s, 7.83MB read
# Requests/sec:   5465.47
# Transfer/sec:    266.87KB



# ----------release版本------------------
# ARC MEM 314.9 M，Last 3.82G
#  wrk -t6 -c100 -d30s --latency http://localhost:8080
# Running 30s test @ http://localhost:8080
#   6 threads and 100 connections
#   Thread Stats   Avg      Stdev     Max   +/- Stdev
#     Latency     2.14ms  697.88us  53.50ms   94.35%
#     Req/Sec     7.52k     1.06k   20.07k    72.70%
#   Latency Distribution
#      50%    2.05ms
#      75%    2.24ms
#      90%    2.53ms
#      99%    4.55ms
#   1347444 requests in 30.10s, 64.25MB read
# Requests/sec:  44763.49
# Transfer/sec:      2.13MB



# # refc MEM 404M，Last 411m
#  wrk -t6 -c100 -d30s --latency http://localhost:8080
# Running 30s test @ http://localhost:8080
#   6 threads and 100 connections
#   Thread Stats   Avg      Stdev     Max   +/- Stdev
#     Latency   133.71ms  387.55ms   1.61s    91.83%
#     Req/Sec    16.77     28.85   145.00     83.87%
#   Latency Distribution
#      50%    0.95ms
#      75%    1.15ms
#      90%  315.37ms
#      99%    1.61s 
#   722 requests in 30.03s, 35.25KB read
#   Socket errors: connect 0, read 0, write 0, timeout 257
# Requests/sec:     24.04
# Transfer/sec:      1.17KB


# ORC MEM 315M，Last 4.02G
# #wrk -t6 -c100 -d30s --latency http://localhost:8080
# Running 30s test @ http://localhost:8080
#   6 threads and 100 connections
#   Thread Stats   Avg      Stdev     Max   +/- Stdev
#     Latency     2.27ms  694.44us  51.43ms   93.80%
#     Req/Sec     7.08k     0.89k    9.55k    71.56%
#   Latency Distribution
#      50%    2.16ms
#      75%    2.38ms
#      90%    2.67ms
#      99%    4.74ms
#   1267753 requests in 30.00s, 60.45MB read
# Requests/sec:  42254.33
# Transfer/sec:      2.01MB
