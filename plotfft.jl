function plotfft(signal,Fs)
           freqs = fftfreq(length(signal),Fs) 
           freqs = freqs[freqs .>=0]
           F = fft(signal)[1:length(freqs)]
           sig = 20 .* log10.((2/length(freqs)).*abs.(F))
           replace!(sig,-Inf=>-300)
           semilogx(freqs ,sig)
       end


