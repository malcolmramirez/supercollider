(
// Load drums
~cpu = PathName("~/dev/samples/samples-extra/cpu").entries.collect({
    arg path;
    Buffer.read(s, path.fullPath);
}).select(_.notNil);

)

(
var targetBreak = (
    kd: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0],
    sd: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0.1, 1, 0, 0, 0, 1, 0],
    ch: 16.collect({ 0.5 + 0.25.rand }),
    zip: [0, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 1, 0, 0, 0, 0, 0, 0, 0, 0]
);

var initializerFunc = {
    (
        kd: 16.collect({ [0, 1].choose }),
        sd: 16.collect({ [0, 0, 0, 0.1, 0.5, 1].wchoose([0.6, 0.1, 0.1, 0.1, 0.05, 0.05]) }),
        ch: 16.collect({ [0, 0.1, 0.3, 0.5, 0.7, 1].wchoose([0.3, 0.2, 0.2, 0.15, 0.1, 0.05]) }),
        zip: 16.collect({ [0, 0.1, 0.4, 0.3, 0.5].wchoose([0.5, 0.3, 0.05, 0.03, 0.02]) })
    )
};

var filterFunc = {
    arg pattern;
    var fitness = 0;
    var instruments = [\kd, \sd, \ch, \zip];

    instruments.do({ |inst|
        pattern[inst].do({ |val, i|
            var diff = (val - targetBreak[inst][i]).abs;
            fitness = fitness + (1 - diff); // higher score for closer match
        });
    });

    fitness = fitness / (instruments.size * 16); // normalize to 0-1 range
    fitness > 0.75
};

var mutationFunc = {
    arg pattern;
    var mutated = pattern.copy;
    var instruments = [\kd, \sd, \ch, \zip];
    var instrument = instruments.choose;
    var position = 16.rand;

    switch(instrument,
        \kd, { mutated[instrument][position] = [0, 1].choose },
        \sd, { mutated[instrument][position] = [0, 0.1, 0.5, 1].choose },
        \ch, { mutated[instrument][position] = (mutated[instrument][position] + 0.2.rand2).clip(0, 1) },
        \zip, { mutated[instrument][position] = [0, 0, 0, 0.3].choose }
    );

    mutated
};

var crossoverFunc = {
    arg parent1, parent2;
    var child = ();
    var instruments = [\kd, \sd, \ch, \zip];

    instruments.do({ |inst|
        child[inst] = 16.collect({ |i|
            if (0.5.coin, {
                parent1[inst][i]
            }, {
                parent2[inst][i]
            })
        });
    });

    child
};

~sim = GeneticSimulation.new(
    mutationFunction: mutationFunc,
    filterFunction: filterFunc,
    crossoverFunction: crossoverFunc,
    initializer: initializerFunc,
    initialPopulationSize: 1000,
    mutationProb: 0.15
);

)

(

var break = (
    kd: [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0],
    sd: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0.1, 1, 0, 0, 0, 1, 0],
    ch: 16.collect({ 0.5 + 0.25.rand }),
    zip: [0, 0, 0, 0, 0, 0, 0.3, 0, 0, 0, 0, 0, 0, 0, 0, 0]
);

var dpMap = (
    kd: 0,
    sd: [3, 18],
    ch: 4,
    zip: 21
);

var initSequence = {
    arg key, pattern, beatdur;
    pattern = pattern[key];
    Routine({
        var sample = dpMap[key];
        pattern.do({
            arg elem;
            if (elem > 0, {
                if (sample.isKindOf(Collection), {
                    sample.do({
                        arg item, i;
                        var mul = elem / sample.size;
                        ~cpu[item].play(mul: mul);
                    });
                },
                {
                    ~cpu[sample].play(mul: elem);
                });
            });
            beatdur.wait;
        });
    });
};

var clock = TempoClock.new(145/60);

Routine({
    loop {
        var numBeats = 4;
        dpMap.keysDo({
            arg key;
            var next = ~sim.next;
            initSequence.value(
                key,
                next,
                numBeats / next[key].size).play(clock: clock);
        });
        numBeats.wait;
    }
}).play(clock: clock);

)