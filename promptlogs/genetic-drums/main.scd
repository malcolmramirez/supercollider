(
var targets = [
    (
        kd: [1, 0, 0, 0, 1, 0, 0, 0],
        pc: [0, 0, 0, 0, 1, 0, 0, 0],
        hh: [0, 0, 0.7, 0, 0, 0, 0.7, 0]
    )
];
var instruments = targets[0].keys;
var numBeats = targets[0][\kd].size;

~drumSim = GeneticSimulation.new(
    mutationFunction: {
        arg pattern;
        var mutated = pattern.copy;
        var instrument = instruments.choose;
        var position = numBeats.rand;
        mutated[instrument][position] = 1.0.rand;
        mutated
    },
    filterFunction: {
        arg pattern;
        var fitness = 0;

        instruments.do({
            arg inst;
            pattern[inst].do({
                arg val, i;
                var fitnessScores = List.fill(targets.size, 0);
                ~targets.do({
                    arg target, ti;
                    var diff = (val - target[inst][i]).abs;
                    // higher score for closer match
                    fitnessScores[ti] = fitnessScores[ti] + (1 - diff);
                });
                fitness = fitness + fitnessScores.maxItem;
            });
        });

        fitness = fitness / (instruments.size * numBeats); // normalize to 0-1 range
        fitness > 0.65
    },
    crossoverFunction: {
        arg parent1, parent2;
        var child = ();
        instruments.do({
            arg inst;
            child[inst] = numBeats.collect({
                arg i;
                var parent = if (0.5.coin) { parent1 } { parent2 };
                parent[inst][i];
            });
        });
        child
    },
    initializer: {
        (
            kd: numBeats.collect({ [0, 1/4, 1/2, 3/4, 1].choose; }),
            pc: numBeats.collect({ [0, 1/4, 1/2, 3/4, 1].choose; }),
            hh: numBeats.collect({ [0, 1/4, 1/2, 3/4, 1].choose; })
        )
    },
    initialPopulationSize: 1000,
    mutationProb: 0.25
);

)

(
~clock = TempoClock.new(145/60);

~wheel = [1, 5/4, 3/2, 9/8, 10/9, 2];
~pollWheel = {
    arg start, size = 4;
    var sign = if (0.5.coin) { 1 } { -1 };
        i = start;
    (
        freqs: size.collect({
            arg item;
            var res = ~wheel[i];
            i = (i + sign) % ~wheel.size;
            res;
        }),
        nextMarker: (i + 1) % ~wheel.size;
    )
};

~wheelEvent = ~pollWheel.(0);

Routine({
    loop {
        var numBeats = 2;
        var next = ~drumSim.next;
        next.keysValuesDo({
            arg key, pattern;
            var beatdur = numBeats / pattern.size;
            Routine({
                pattern.do({
                    arg amp;
                    if (amp > 0) {
                        Synth(key, [\amp, amp]);
                    };
                    beatdur.wait;
                });
            }).play(clock: ~clock);
        });
        numBeats.wait;
    }
}).play(clock: ~clock);

Routine({
    var dur = 32;
    loop {
        var freqs = 180 * ~wheelEvent.freqs;
        //("pad" ++ freqs).postln;
        freqs.do({
            arg freq;
            Synth(\pad, [
                \freq, freq,
                \atk, 0.5 + 2.0.rand,
                \suslev, 1 - 0.5.rand,
                \rel, 7.5 + 5.0.rand,
                \lpff, rrand(250, 1500),
                \lfo, rrand(2, 8),
                \amp, 0.25
            ])
        });
        dur.wait;
        ~wheelEvent = ~pollWheel.(~wheelEvent.nextMarker);
    }
}).play(clock: ~clock);

Routine({
    var dur = 0.25;
    loop {
        var freqs = 360 / 3 * ~wheelEvent.freqs;
        //("arp" ++ freqs).postln;

        freqs.do({
            arg freq;
            Routine({
                Synth(\pad, [
                    \freq, freq * (1 + 3.rand),
                    \atk, 0.25 / (6.rand + 2),
                    \suslev, 1,
                    \rel, 0.25 + 0.5.rand,
                    \sustime, 0.25 / 4,
                    \lpff, rrand(250, 1500),
                    \lfo, rrand(2, 8),
                    \amp, 0.1,
                    \formantAmt, 0.25.rand
                ]);
            }).play(clock: ~clock);
            dur.wait;
        });
    }
}).play(clock: ~clock);
)
