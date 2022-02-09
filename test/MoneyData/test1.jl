import VL_LimitOrderBook
using VL_LimitOrderBook: Monetary, M,
             AssetMismatch,
             convert, decimals, name

USD_10_57 = M(:USD, "10.57")
USD_9_21 = M(:USD, "9.21")
EUR_0_533 = M(:EUR, "0.533")


println(USD_10_57 + USD_9_21)

println(USD_9_21 - USD_10_57)

println(USD_10_57 - USD_9_21)

println(USD_10_57 < USD_9_21)

println(USD_10_57 > USD_9_21)


println(+ USD_10_57)
println(- USD_10_57)
println(abs(- USD_10_57))

println(USD_10_57 * 10 + 2)
