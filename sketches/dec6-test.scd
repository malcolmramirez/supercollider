UnitTest.gui;

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
        [SinOsc.ar(\freq.kr(330) * pitchEnv)],
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

Ndef(\saw, {
    var sig, env, imp;

    imp = \imp.kr;
    env = Env.perc(0.01, \rel.kr(b*4)).ar(gate: imp);
    
    sig = Saw.ar(\freq.kr([0,0,0,0]));
    sig = LPF.ar(sig, 
                 SinOsc.ar(b/2).linlin(-1, 1, 200, 2400), 
                 SinOsc.ar(b*6).linlin(-1, 1, 0.1, 2));
    sig = sig * env;
    
    sig = Pan2.ar(sig, \pan.kr(0));

    sig;
})
)

(
Ndef(\kick)
    .map(\imp, SP(\kp).pat("[1 <~ 1> ~ [1 1 1 ~]]"))
    .play;

Ndef(\snare)
    .map(\imp, SP(\sp).pat("1(<8 8 8 5> 16 4)"))
    .play;

Ndef(\hh)
    .map(\imp, SP(\hp).pat("1(6 16 4)"))
    .play;

Ndef(\saw)
    .map(\imp, SP(\np2).pat("1"))
    .map(\freq, SP(\np)
                    .hold_(true)
                    .pat("c3_maj7"))
    .play;
)

// GOAL:
(
Syn(\kick)
    .imp_t("<1(5 16) 1(5 16) [1 1 1 1]>")

Syn(\snare)
    .imp_t("1(2 16 6)")
    .freq("[e5 <a5 g5>]")
    .play;

Syn(\hh)
    .imp_t("1(16 16)")
    .play;

Syn(\saw)
    .imp_t("1(16 16)")
    .rel(b/4)
    .pan("`rrand(-1.0, 1.0)`(16 16)")
    .freq("c3 e4 g3 b3 <c3 d4> <e4 [c3 e4 g3 b4] c4> g3 b3")
    .play;
)

(

Ndef(\kick)
    .map(\imp, SP(\kp).pat("<1(5 16) 1(5 16) [1 1 1 1]>"))
    .play;

Ndef(\snare)
    .map(\freq, SP(\fp2).hold_(true).pat("[e5 <a5 g5>]"))
    .map(\imp, SP(\sp).pat("1(2 16 6)"))
    .play;

Ndef(\hh)
    .map(\imp, SP(\hp).pat("1(16 16)"))
    .play;

Ndef(\saw)
    .map(\imp, SP(\np2).pat("1(16 16)"))
    .map(\rel, { b/4 })
    .map(\pan, SP(\pn).pat("`rrand(-1.0, 1.0)`(16 16)"))
    .map(\freq, SP(\np).hold_(true).pat("c3 e4 g3 b3 <c3 d4> <e4 [c3 e4 g3 b4] c4> g3 b3"))
    .play;
)

UnitTest.runAll;
