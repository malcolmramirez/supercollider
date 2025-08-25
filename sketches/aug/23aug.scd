(
// Load drums
~cpu = PathName("~/dev/samples/samples-extra/cpu").entries.collect({
    arg path;
    Buffer.read(s, path.fullPath);
}).select(_.notNil);

~kickGene = GeneticSimulation.new(
    {
        arg list;
        list.wrapPut(rand(list.size) * 2, 1);
        list;
    },
    {
        arg list;
        (list.sum < 4);
    },
    {
        arg left, right;
        var crossover = left.size.rand;
        var child = List.new;
        left.do({
            arg item, i;
            if (i < crossover, {
                child.add(left[i]);
            },
            {
                child.add(right[i]);
            });
        });
        child;
    },
    {
        var list = List.fill(8, 0);
        list[2] = 1;
        list[5] = 1;
        if (0.5.coin, {
            list[0] = 1;
        });
        list;
    },
    4,
    0.25);

~snareGene = GeneticSimulation.new(
    {
        arg list;
        list.do({
            arg item, i;
            var ghost;
            if ((item > 0) && (0.25.coin), {
                ghost = (i - 1) % list.size;
                list[ghost] = 0.5 * item;
            });
        });
        list;
    },
    {
        arg list;
        (list.sum < 3) && (list.sum > 1);
    },
    {
        arg left, right;
        var crossover = left.size.rand;
        var child = List.new;
        left.do({
            arg item, i;
            if (i < crossover, {
                child.add(left[i]);
            },
            {
                child.add(right[i]);
            });
        });
        child;
    },
    {
        var list = List.fill(8, 0);
        list[4] = 1;
        list;
    },
    4,
    0.25
);

~hihatGene = GeneticSimulation.new(
    {
        arg list;
        list;
    },
    {
        arg list;
        (list.sum < 8) && (list.sum > 4);
    },
    {
        arg left, right;
        var crossover = left.size.rand;
        var child = List.new;
        left.do({
            arg item, i;
            if (i < crossover, {
                child.add(left[i]);
            },
            {
                child.add(right[i]);
            });
        });
        child;
    },
    {
        var list = List.fill(8, { 0.75.rand + 0.25 });
        list[1] = 1;
        list[5] = 1;
    },
    4,
    0.25);
)

(
var clock = TempoClock(150/60);

var kick = Routine({
    loop {
        var nxt = ~kickGene.next;
        nxt.do({
            arg elem;
            if (elem == 1, {
                ~cpu[0].play;
            });
            0.25.wait;
        });
    };
}).play(clock: clock);

var snare = Routine({
    loop {
        var nxt = ~snareGene.next;
        nxt.do({
            arg elem;
            if (elem > 0, {
                ~cpu[3].play(mul: elem);
            });
            0.25.wait;
        });
    };
}).play(clock: clock);

var hihat = Routine({
    loop {
        var nxt = ~hihatGene.next;
        nxt.do({
            arg elem;
            if (elem > 0, {
                ~cpu[4].play(mul: elem);
            });
            0.25.wait;
        });
    };
}).play(clock: clock);

)