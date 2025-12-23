p.clear;
(
d = { |path|
    PathName(path)
        .entries
        .select { |f| f.extension == "wav" }
        .collect { |f|
            Buffer.read(s, f.fullPath);
        };
}.("~/dev/samples/samples-extra/break");

SynthDef(\slicer, {
    var bufnum = \bufnum.kr;
    var numSlices = \numSlices.kr(1);

    var beatsPerSecond = (\tempo.kr); // bps
    var secondsPerBar = \barlen.kr(4) / beatsPerSecond;

    var secondsPerFrame = BufFrames.kr(bufnum) / BufSampleRate.kr(bufnum);
    var framesPerSlice = BufFrames.kr(bufnum) / numSlices;

    var atk = (secondsPerBar / numSlices) * \begin.kr(0);
    var rel = (secondsPerBar / numSlices) * \end.kr(1);

    var sig = PlayBuf.ar(
        numChannels: 2,
        bufnum: bufnum,
        rate: secondsPerFrame / secondsPerBar,
        doneAction: 2,
        startPos: framesPerSlice * \slice.kr(0)
    );

    sig = sig * \amp.kr(1);
    sig = sig * Env.perc(
        atk,
        rel,
        curve: \curve.kr(100)
    ).ar(Done.freeSelf);

    Out.ar(\i_out.kr(0), sig);
}).add;

SynthDef(\saw, {
    var sig, env;

    env = Env([0, 1, 1, 0], [\atk.kr(0.1), \sust.kr(0), \rel.kr(1)], curve: \curve.kr(-4))
        .kr(Done.freeSelf);
    
    sig = Saw.ar(\freq.kr(440)) * env * \amp.kr(1); 
    sig = Pan2.ar(sig, \pan.kr(0));

    Out.ar(\i_out.kr(0), sig);
}).add;

SynthDef(\kick, {
    var sig, env, pitchEnv, imp;

    env = Env.perc(0.001, 0.2).ar(Done.freeSelf);
    pitchEnv = Env([1, 2.5, 1], [0.001, 0.001], curve: -4).ar;
    
    sig = SinOsc.ar(55 * pitchEnv);
    sig = sig * env * \amp.kr(1);
    sig = sig.tanh;

    Out.ar(\i_out.kr(0), sig!2);
}).add;
)

(
p = ProxySpace(s);
b = 150/60;
p.makeTempoClock(b);
p.fadeTime_(0).quant_(4);
p.push;
)

~break.play;
(
~break[0] = Pbind(
    \instrument, \slicer,
    \numSlices, 16,
    // \slice, Pseq((0..15).mirror1.pyramid(10), inf),
    \slice, Pseq([
        Pseq([0,1,4,2,4,5,6,7,8,9,10,11,12,13,14,13], 1),
        Pseq([0,1,2,2,4,5,6,7,8,8,10,11,12,13,14,13], 1),
    ], inf),
    \tempo, b/2,
    \barlen, 4,
    \dur, Pkey(\barlen) / Pkey(\numSlices),
    \begin, Pseq([
        Pwrand([0, 0.5], [8, 1].normalizeSum, 15),
        0.5
    ], inf),
    \end, 1,
    \amp, 3.dbamp,
    \curve, 5,
    \bufnum, d[9]
);
~break[1] = \filterIn -> { |in| HPF.ar(in, SinOsc.ar(b/4).range(400, 1600)) }
)

~kick.play;
(
~kick[0] = Pbind(
    \instrument, \kick,
    \dur, Pseq([
        Pn(1/2, 15),
        Pseq([Rest(1/4), 1/8, Rest(1/8)])
    ], inf),
    \amp, 8.dbamp
);
)

~saw.end(4);

~saw.play;
(
~saw[0] = Pbind(
    \instrument, \saw,
    \degree, Pseq([
        [1,3,7],
        [1,3,11],
        [2,6,8],
        [3,8,13],
        [2,6,8],
    ], inf),
    // \octave, Pseq([3,4,Pwrand([3,5], [1.5,1].normalizeSum)], inf),
    \octave, 6,
    \atk, 0.03,
    \rel, 0.05,
    \amp, 1.dbamp, 
    \dur, Pseq([1/8, Pwrand([1/8, Rest(1/8)], [2, 1].normalizeSum)], inf),
    \pan, Pwhite(-1, 1)
);

~saw.set(\wet3, 0.65);

~saw[1] = \filterIn -> { |in| 
    var sig;
    
    sig = RLPF.ar(
        in, 
        LFPulse.ar(b/6).range(400, 800) * LFNoise2.ar(b/2).range(1, 1.25), 
        Saw.ar(b).range(1, 2).reciprocal);

    sig;
};

~saw[3] = \filterIn -> { |in| 
    FreeVerb.ar(
        in, 
        0.75, 
        SinOsc.ar(b/2).range(0.25, 0.5),
        LFNoise1.ar(b*4).range(0.25, 0.5))
};

)

~pad.play;
(
~pad[0] = Pbind(
    \instrument, \saw,
    \degree, Pseq([
        [1,3,7],
        [1,3,11],
        [2,6,8],
        [3,8,13],
        [2,6,8],
    ], inf),
    // \octave, Pseq([3,4,Pwrand([3,5], [1.5,1].normalizeSum)], inf),
    \octave, 4,
    \atk, 1,
    \sust, 1,
    \rel, 3,
    \curve, 3,
    \amp, -7.5.dbamp, 
    \dur, 4 
);

~pad[1] = \filterIn -> { |in| 
    RLPF.ar(in, 800);
};

~pad[2] = \filterIn -> { |in| 
    FreeVerb.ar(
        in, 
        0.5, 
        SinOsc.ar(b*2).range(0.5, 1));
};
)
