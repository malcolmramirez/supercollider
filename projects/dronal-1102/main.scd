(
Quarks.install("https://github.com/madskjeldgaard/nodeproxygui2")
)

(
var readSoundFiles = { |folder|
    PathName(folder).entries.collect({ |file|
        if (file.extension == "wav") {
            Buffer.readChannel(s, file.fullPath, channels:0);  // fullPath handles spaces automatically
        };
    });
};

~breaks = readSoundFiles.("~/dev/samples/samples-extra/break");
)

(

SynthDef(\bufgrain, {
    var sig, env;

    sig = GrainBuf.ar(
        2,
        Dust.ar(2),
        dur: \dur.kr(1),
        sndbuf: \buf.kr,
        rate: \rate.kr(1),
        pos: WhiteNoise.ar,
        envbufnum: \envbufnum.kr(-1),
        maxGrains: \maxGrains.kr(512)
    );
    
    Out.ar(\out.kr(0), sig);
})
)

(
Ndef(\microphone, { SoundIn.ar(0) }).gui;
)

(

Spec.add(\rateFreq, [1, 1000, \lin, 1, 10]);
Spec.add(\grainPerSecMin, [0, 1000, \lin, 1, 10]);
Spec.add(\grainPerSecMax, [0, 1000, \lin, 1, 50]);
Spec.add(\durScrubFreq, [0, 1000, \lin, 0.05, 0.5]);

Spec.add(\posScrubFreq, [0.1, 100, \lin, 0.025, 0.1]);
Spec.add(\rlpfChaosFreq, [1, 100, \lin, 1, 10]);
Spec.add(\durMin, [0, 1, \lin, 0.00001, 0.025]);
Spec.add(\durMax, [0, 1, \lin, 0.00001, 0.1]);

Spec.add(\n1, [1, 10, \lin, 0.01, 1]);
Spec.add(\n2, [1, 10, \lin, 0.01, 3/2]);
Spec.add(\n3, [1, 10, \lin, 0.01, 12/7]);
Spec.add(\n4, [1, 10, \lin, 0.01, 2]);

Spec.add(\rlpfModFreqMax, [1, 100, \lin, 1, 4]);
Spec.add(\rlpfChaosFreq, [1, 100, \lin, 1, 10]);
Spec.add(\freq, [20, 1000, \lin, 1, 220]);

Ndef(\grain, {
    var sig,
        ratefreq = \rateFreq.kr(10);

    sig = GrainBuf.ar(
        2,
        Impulse.ar(SinOsc.ar(0.1).linlin(-1, 1, \grainPerSecMin.kr(10), \grainPerSecMax.kr(50))),
        dur: (SinOsc.ar(\durScrubFreq.kr(0.5))).linlin(-1, 1, \durMin.kr(0.025), \durMax.kr(0.1)), 
        sndbuf: ~breaks[0],
        rate: (SinOsc.ar(ratefreq) + LFNoise2.ar(ratefreq/10).abs).linlin(-2, 2, 0.25, 2),  
        pos: (WhiteNoise.ar + SinOsc.ar(\posScrubFreq.kr(0.1))).linlin(-2, 2, 0, 1)
    );

    sig = sig * \amp.kr(0.9);

    Out.ar(\out.kr(0), sig);
}).gui2;

Ndef(\syn, {
    var sig, freqs, freq;

    freq = \freq.kr(110);

    freqs = freq * [[\n1.kr(1), \n2.kr(3/2), \n3.kr(12/7), \n4.kr(2)]];
        
    sig = freqs[0].collect{|f| Saw.ar(f) };
    
    sig = Splay.ar(sig);

    sig = sig * \amp.kr(1/4);
    sig = RLPF.ar(
        sig, 
        freq + freq * (
            SinOsc.ar((Saw.ar(0.1).linlin(-1, 1, 1, \rlpfModFreqMax.kr(4)))) + LFNoise2.ar(\rlpfChaosFreq.kr(10)).abs + 1),
        (pow(1/16, SinOsc.ar(\rqModFreq.kr(0.5)).linlin(-1, 1, 0, 0.35))) * 0.5
    );

    Out.ar(\out.kr(0), sig)
}).gui2;

)
