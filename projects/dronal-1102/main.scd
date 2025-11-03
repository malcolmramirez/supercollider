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

)
(
Ndef(\grain0, {
    var sig;

    sig = GrainBuf.ar(
        2,
        Dust.ar(10),
        dur: (SinOsc.ar(0.5).abs) * 0.25,
        sndbuf: ~breaks[8],
        rate: 1,  
        pos: (Saw.ar(0.1) + 1) * ((LFNoise2.ar(1) * 0.1) + 1),
        envbufnum: \envbufnum.kr(-1),
        maxGrains: \maxGrains.kr(512)
    );

    sig = sig * \amp.kr(1);

    Out.ar(\out.kr(0), sig);
}).play
)

(
Ndef(\grain1, {
    var sig, freqs;

    freqs = 440 * [[1, 3/2, 12/7, 2], [3/2, sqrt(2) + 1, 2, 12/7]];
        
    sig = freqs[0].collect{|f| Saw.ar(f) };
    
    sig = Splay.ar(sig);

    sig = sig * \amp.kr(1/3);
    sig = RLPF.ar(
        sig, 
        440 + 220 * (
            SinOsc.ar((Saw.ar(5) + 1) * 2) + 
            LFNoise2.ar(10).abs + 1),
        (pow(1/16, SinOsc.ar(1)) + 1) * 0.5
    );

    Out.ar(\out.kr(0), sig)
}).play
)
