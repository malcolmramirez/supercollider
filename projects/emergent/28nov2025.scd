(
TempoClock.default.tempo = (150/60);

b = TempoClock.default.tempo / 4;

Ndef(\kick, {
    var sig, env, pitchEnv, imp;

    imp = \imp.kr;
    env = Env.perc(0.01, 0.075).ar(gate: imp);
    pitchEnv = Env([1, 2, 1], [0.01], curve: -4).ar(gate: imp);
    
    sig = SinOsc.ar(55 * pitchEnv);
    sig = sig * env * 5.dbamp;

    sig!2;
});

Ndef(\snare, {
    var sig, env, pitchEnv, imp;

    imp = \imp.kr;    
    env = Env.perc(0.01, 0.1).ar(gate: imp);
    pitchEnv = Env([1, 2, 1], [0.01], curve: -1).ar(gate: imp);
    
    sig = Mix.ar(
        [SinOsc.ar(330 * pitchEnv)],
        Hasher.ar(
            [Saw.ar(220), Pulse.ar(334), SinOsc.ar(110)]) 
                * 0.5 
                * Env.perc(0.05, 0.02).ar(gate: imp));
    sig = sig * env * 20.dbamp;
    sig = RLPF.ar(sig, 220, pitchEnv.linlin(1, 2, 0.05, 1));
    sig = Resonz.ar(sig, 440, 8 * SinOsc.ar(0.5).linlin(-1, 1, 1, 2));

    sig!2;
});

Ndef(\hh, {
    var sig, env, pitchEnv, imp;

    imp = \imp.kr;
    env = Env.perc(0.001, 
                   TRand.kr(0.01, 0.05, imp))
             .ar(gate: imp);
    pitchEnv = Env([1, 2, 1], [0.01], curve: -4).ar(gate: imp);
    
    sig = WhiteNoise.ar * 0.65;
    sig = BPF.ar(sig, 
                 SinOsc.ar(b/2).linlin(-1, 1, 200, 2400), 
                 SinOsc.ar(b*6).linlin(-1, 1, 0.1, 2));
    sig = sig * env;
    
    sig = Pan2.ar(sig, TRand.kr(-1, 1, imp));

    sig;
});
)

(
Ndef(\kickPat, {
    EucImpulse.kr(5, 16, speed: 4)
});
Ndef(\snarePat, {
    EucImpulse.kr(2, 16, 8, speed: 4)
});
Ndef(\hhPat, { 
    EucImpulse.kr(4, 8, speed: 4) 
});
)

(
Ndef(\kick)
    .map(\imp, Ndef(\kickPat))
    .play;

Ndef(\snare)
    .map(\imp, Ndef(\snarePat))
    .play;

Ndef(\hh)
    .map(\imp, Ndef(\hhPat))
    .fadeTime_(b)
    .play;
)
