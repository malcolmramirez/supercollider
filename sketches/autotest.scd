(

)

(

var buf, slicer, fxBus, fx, auto;

TempoClock.default = TempoClock(150/60);

buf = ~dirt.buffers[\break][1];
fxBus = Bus.audio(s, 2);

fork {
    SynthDef(\fx, {
        var in = In.ar(\in.kr(0), 2);
        in = HPF.ar(in, \hpf.kr(5000));
        in =
        Out.ar(\out.kr(0), in);
    }).add;
    s.sync;

    slicer = Slicer.new(buffer: buf, rateMultiplier: 1, out: fxBus);
    fx = Synth(\fx, [\in, fxBus]);
    auto = Automator(fx);
    auto.run(32, [
        [
            \param, \hpf,
            \func, {|x| sin(x)},
            \over, [0, 32*pi],
            \range, [100, 5000]
        ]
    ]);
    slicer.play;
}

)