using ADCME
using PyCall
using LinearAlgebra
using PyPlot
using Random
Random.seed!(233)

if Sys.islinux()
py"""
import tensorflow as tf
libTwoLayer = tf.load_op_library('build/libTwoLayer.so')
@tf.custom_gradient
def two_layer(x):
    y = libTwoLayer.two_layer(x)
    def grad(dy):
        return libTwoLayer.two_layer_grad(dy, y, x)
    return y, grad
"""
elseif Sys.isapple()
py"""
import tensorflow as tf
libTwoLayer = tf.load_op_library('build/libTwoLayer.dylib')
@tf.custom_gradient
def two_layer(x):
    y = libTwoLayer.two_layer(x)
    def grad(dy):
        return libTwoLayer.two_layer_grad(dy, y, x)
    return y, grad
"""
elseif Sys.iswindows()
py"""
import tensorflow as tf
libTwoLayer = tf.load_op_library('build/libTwoLayer.dll')
@tf.custom_gradient
def two_layer(x):
    y = libTwoLayer.two_layer(x)
    def grad(dy):
        return libTwoLayer.two_layer_grad(dy, y, x)
    return y, grad
"""
end

two_layer = py"two_layer"

x = zeros(10);
# TODO: specify your input parameters
u = two_layer(x)
sess = Session()
init(sess)
run(sess, u)
error()

# TODO: change your test parameter to `m`
# gradient check -- v
function scalar_function(m)
    return sum(tanh(two_layer(x)))
end

# TODO: change `m_` and `v_` to appropriate values
m_ = constant(rand(10,20))
v_ = rand(10,20)
y_ = scalar_function(m_)
dy_ = gradients(y_, m_)
ms_ = Array{Any}(undef, 5)
ys_ = Array{Any}(undef, 5)
s_ = Array{Any}(undef, 5)
w_ = Array{Any}(undef, 5)
gs_ =  @. 1 / 10^(1:5)

for i = 1:5
    g_ = gs_[i]
    ms_[i] = m_ + g_*v_
    ys_[i] = scalar_function(ms_[i])
    s_[i] = ys_[i] - y_
    w_[i] = s_[i] - g_*sum(v_.*dy_)
end

sess = Session()
init(sess)
sval_ = run(sess, s_)
wval_ = run(sess, w_)
close("all")
loglog(gs_, abs.(sval_), "*-", label="finite difference")
loglog(gs_, abs.(wval_), "+-", label="automatic differentiation")
loglog(gs_, gs_.^2 * 0.5*abs(wval_[1])/gs_[1]^2, "--",label="\$\\mathcal{O}(\\gamma^2)\$")
loglog(gs_, gs_ * 0.5*abs(sval_[1])/gs_[1], "--",label="\$\\mathcal{O}(\\gamma)\$")

plt.gca().invert_xaxis()
legend()
xlabel("\$\\gamma\$")
ylabel("Error")
