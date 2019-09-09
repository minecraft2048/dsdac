using FFTW
using DSP
using PyPlot

include("./plotfft.jl")

# System variables
Fs = 48000
n = 1:48000

#Input signal

Fsig = sin.(2*pi*440/Fs .* n) + sin.(2*pi*16000/Fs .* n) 
#Fsig = zeros(48000)

#DSP functions

#Do upsampling by inserting zero signals 
function upsample(signal,factor)
    out = Float64[]
    for s = signal
        push!(out,s)
        for i = 1:factor-1
            push!(out,0.0)
        end
    end
    return out
end

#Do moving average filter y[n] = (x[n] + x[n-1])/2
function movingavg(sig)
    out = zeros(size(sig)[1])
    for i = 2:size(sig)[1]
        out[i] = (sig[i]+sig[i-1])
    end
return out
end

#Implement the final quantizer
function comparator(signal)
    if signal > 0.0001 return 1.0
    elseif signal < -0.0001 return  -1.0
    else return 0
    end
end

#2rd order delta sigma DAC

function dsdac(signal)
    outarray = zeros(size(signal)[1])
    reg1 = 0.0
    reg2 = 0.0
    reg3 = 0.0
    out = 0.0
    out2 = 0.0
    ret = 1.0
    for i = 1:size(signal)[1]
        input = signal[i]
        out = reg3
        outarray[i] = out
        ret = comparator(out)
        reg3 = reg3 + input - ret 
    end
    return outarray
end

#Another delta sigma implementation that closely follows how it would be implemented on hardware
function dsdac2(signal)
    outarray = zeros(size(signal)[1])
    reg_in = [0.0,0.0,0.0,0.0]
    reg_out = [0.0,0.0,0.0,0.0]

    for i = 1:size(signal)[1]
        bitstream = comparator(reg_out[2])
        outarray[i] = reg_out[2]
        input = signal[i]
        integrator_1_out = input - bitstream + reg_out[1]
        reg_in[2] = integrator_1_out - bitstream + reg_out[2]
        #reg_in[3] = reg_out[2] - bitstream + reg_out[3]
        #reg_in[4] = reg_out[2] - bitstream + reg_out[4]    
        reg_out = deepcopy(reg_in)
    end
    return outarray
end

#Test delta sigma DAC by using DSP.jl built in interpolator and upsampled signal filtered with 3x moving average filter 
good_resample = comparator.(dsdac2(resample(Fsig,128)))
diy_resample = comparator.(dsdac2(movingavg(movingavg(movingavg(upsample(resample(Fsig,8),32))))))
