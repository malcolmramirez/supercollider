(

)

(

var buf, slicer, fxBus, fx, auto;

TempoClock.default = TempoClock(150/60);

buf = ~dirt.buffers[\break][1];
fxBus = Bus.audio(s, 2);

fork {
    SynthDef(\fx, {
        var in;
        in = In.ar(\in.kr(0), 2);
        in = in * \amp.kr(1);
        Out.ar(\out.kr(0), in);
    }).add;
    s.sync;

    slicer = Slicer.new(buffer: buf, rateMultiplier: 1, out: fxBus);
    fx = Synth(\fx, [\in, fxBus]);
    auto = Automator(fx);
    auto.run(16, (amp: (xrange: [0, 8*pi], from: 0.25, to: 0.75, func: {|x| cos(x)})));
    slicer.play;
}

)