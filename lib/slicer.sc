Slicer {

    var args, transitionFunction, currentSlice, waitTime;

    *new {
        arg
        buffer,
        rateMultiplier=1,
        startSlice=0,
        transitionFunction=nil,
        args=#[],
        numSlices=16,
        clock=TempoClock.default;

        var sampleDur, playbackRate, waitTime;

        if (transitionFunction == nil) {
            transitionFunction = {|i| (i + 1) % numSlices};
        };
        sampleDur = buffer.numFrames / buffer.sampleRate;

        playbackRate = sampleDur / (clock.beatsPerBar / clock.tempo) * rateMultiplier;

        SynthDef(\Slicer_playbuf, {
            var sig, start, playDur;

            start = \bufferFrames.kr * (\slice.kr / \numSlices.kr) * \rateMultiplier.kr;
            sig = PlayBuf.ar(numChannels: 2, startPos: start, bufnum: \buffer.kr, rate: \playbackRate.kr);
            sig = sig * \amp.kr(1);
            sig = sig * Env.perc(0, \playDur.kr, curve: 100).kr(Done.freeSelf);

            Out.ar(\out.kr(0), sig ! 2);
        }).add;

        waitTime = (clock.beatsPerBar * (1 / numSlices));

        args = args ++ [
            \buffer, buffer,
            \bufferFrames, buffer.numFrames,
            \numSlices, numSlices,
            \rateMultiplier, rateMultiplier,
            \playbackRate, sampleDur / (clock.beatsPerBar / clock.tempo) * rateMultiplier,
            \playDur, (playbackRate / numSlices),

        ];

        ^super.newCopyArgs(args, transitionFunction, startSlice, waitTime);
    }

    play {
        arg s = Server.default;
        fork {
            loop {
                s.bind {
                    Synth(\Slicer_playbuf, args ++ [\slice, currentSlice]);
                };
                currentSlice = transitionFunction.(currentSlice);
                waitTime.wait;
            }
        }
    }
}