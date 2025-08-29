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

var initializerFunc = {
    (
        kd: numBeats.collect({ [0, 1/4, 1/2, 3/4, 1].choose; }),
        pc: numBeats.collect({ [0, 1/4, 1/2, 3/4, 1].choose; }),
        hh: numBeats.collect({ [0, 1/4, 1/2, 3/4, 1].choose; })
    )
};


var filterFunc = {
    arg pattern;
    var fitness = 0;

    instruments.do({
        arg inst;
        pattern[inst].do({
            arg val, i;
            var fitnessScores = List.fill(targets.size, 0);
            targets.do({
                arg target, ti;
                var diff = (val - target[inst][i]).abs;
                fitnessScores[ti] = fitnessScores[ti] + (1 - diff); // higher score for closer match
            });
            fitness = fitness + fitnessScores.maxItem;
        });
    });

    fitness = fitness / (instruments.size * numBeats); // normalize to 0-1 range
    fitness > 0.65
};

var mutationFunc = {
    arg pattern;
    var mutated = pattern.copy;
    var instrument = instruments.choose;
    var position = numBeats.rand;
    mutated[instrument][position] = 1.0.rand;
    mutated
};

var crossoverFunc = {
    arg parent1, parent2;
    var child = ();
    instruments.do({
        arg inst;
        child[inst] = numBeats.collect({
            arg i;
            if (0.5.coin, {
                parent1[inst][i]
            }, {
                parent2[inst][i]
            })
        });
    });

    child
};

~drumSim = GeneticSimulation.new(
    mutationFunction: mutationFunc,
    filterFunction: filterFunc,
    crossoverFunction: crossoverFunc,
    initializer: initializerFunc,
    initialPopulationSize: 1000,
    mutationProb: 0.25
);

)

(

var clock = TempoClock.new(145/60);

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
                    if (amp > 0, {
                        Synth(key, [\amp, amp]);
                    });
                    beatdur.wait;
                });
            }).play(clock: clock);
        });
        numBeats.wait;
    }
}).play(clock: clock);


)