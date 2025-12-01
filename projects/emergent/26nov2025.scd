(
var chord = Note.toFreq("fs3_maj7");
var name = { |prefix, i|
    (prefix.asString ++ i.asString).asSymbol
};
b = TempoClock.default.tempo * 4;

Ndef(\lfo0, { LFNoise2.ar(b*2) });
Ndef(\lfo1, { LFNoise2.ar(b) });
Ndef(\lfo2, { LFNoise2.ar(b/2) });
Ndef(\lfo3, { LFTri.ar(b/8) });

Ndef(\freq0, { \f.kr * Ndef(\lfo3).ar.linlin(-1, 1, 1.001, 1.01)});
Ndef(\freq1, { \f.kr });
Ndef(\freq2, { \f.kr });
Ndef(\freq3, { \f.kr });

4.do { |i| 
    Ndef(name.(\s, i), {
        var sig, env, imp, 
            atk, lev, rel,
            freq, lfo, impr;
        
        freq = Ndef(name.(\freq, i)).ar(1);
        lfo = Ndef(name.(\lfo, i)).ar(1);
        impr = b/2;
        atk = (lfo + LFNoise2.ar(b*2) * 0.25).linlin(-1.25, 1.25, 0.01, 0.5);
        rel = lfo.linlin(-1, 1, 0.5, 1);
        sig = Saw.ar(freq);
        imp = Impulse.kr(impr);
        lev = TRand.kr(0.25, 1, imp);
        env = Env.perc(atk, rel).ar(gate: imp);
        sig = sig * env;
        
        sig = RLPF.ar(
                sig, 
                lfo.linlin(-1, 1, 220 - (i * 55), 880), 
                lfo.linlin(-1, 1, 0.5, 1).sqrt);
        
        sig = sig * lev * \vol.kr(0.45);
        sig; 
    });
};

Ndef(\fx0, { 
    var combed, sig;
    
    sig = \in.ar(1);

    combed = CombC.ar(LPF.ar(sig, 800), b*4, b/6, b);
    
    sig = HPF.ar(sig, 1200);
    sig = Pan2.ar(sig, TRand.kr(-1, 1, Impulse.kr(b*4)));

    sig = combed + sig;

    sig / 2;
});

Ndef(\fx1, {
    var sig;

    sig = FreeVerb.ar(
        \in.ar, 
        Ndef(\lfo2).ar.linlin(-1, 1, 0.5, 0.9),
        Ndef(\lfo3).ar(1).linlin(-1, 1, 0.25, 0.99))!2;

    sig = HPF.ar(sig, 100);

    sig;
});

Ndef(\fx2, {
    var sig;
    sig = \in.ar;
    sig = Resonz.ar(
        sig, 
        Pitch.kr(sig) * SinOsc.ar(b/2).linlin(-1, 1, 1, 3), 
        2);
    sig = sig * -1.dbamp;
    sig = Mix.ar(sig);
    Pan2.ar(sig, TIRand.kr(-1, 1, Impulse.kr(b*2)));
});

Ndef(\fx3, {
    var sig;
    sig = \in.ar;
    sig = MoogFF.ar(
        sig, 
        Pitch.kr(sig)[0] * Ndef(\lfo3).ar.linlin(-1, 1, 2, 10), 
        Ndef(\lfo2).ar.linlin(-1, 1, 0.1, 3));  
    sig ! 2;
});

Tdef(\controlPattern, {
    var chords = Alt("fs3_maj7", "a3_min7", "ds3_min7", "bf3_maj7"); 
    loop {
        var chord = Note.toFreq(chords.value);
        var routing = [0, 1, 2, 3].scramble;
        4.do { |i|
            var syn = name.(\s, routing[i]);
            var fx = name.(\fx, i);
            var freq = name.(\freq, i);
            
            Ndef(freq).set(\f, chord[i]); 
            Ndef(fx) <<> Ndef(syn);
            Ndef(fx).play;
        };
        4.wait;
    }
}).play;

)
