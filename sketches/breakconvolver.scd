b = Buffer.alloc( s, 2048, 1, _.zeroMsg );
(
    x = { arg i_kernel, density = 100, trigPeriod = 5.0, cutOff = 1000, minFreq = 200, maxFreq = 2000;
        var input, trigFreq, recTrig, irSig, convTrig, convTrigs, bufFrames, conv1, conv2;

        input        = LPF.ar( Dust2.ar( density ), cutOff );
        trigFreq        = trigPeriod.reciprocal;
        recTrig        = Impulse.kr( trigFreq );
        irSig        = Saw.ar( TExpRand.kr( minFreq, maxFreq, recTrig ), 0.4 );
        RecordBuf.ar( irSig, i_kernel, recTrig, loop: 0, trigger: recTrig );
        convTrig        = TDelay.kr( recTrig, BufDur.ir( i_kernel ));
        // split updates across two triggers. Note that [ 1, 0 ] creates
        // a MultiChannel expansion!
        convTrigs        = PulseDivider.kr( convTrig, 2, [ 1, 0 ]);
        bufFrames        = BufFrames.ir( i_kernel );
        // create the two alternatingly updated convolution ugens
        #conv1, conv2    = Convolution2.ar( input, i_kernel, convTrigs, bufFrames );

        XFade2.ar( conv1, conv2, LFTri.kr( trigFreq * 0.5, 1 )) ! 2;
    }.play( s, [ \i_kernel, b ]);
)

x.set( \trigPeriod, 0.1 );    // fast changes
x.set( \trigPeriod, 10.0 );    // slow changes
x.free;    // delete synth