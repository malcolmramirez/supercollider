GeneticSimulation {

    var mutationFunction,
        filterFunction,
        crossoverFunction,
        initializer,
        mutationProb,
        population,
        currMember;

    *new {
        arg mutationFunction,
            filterFunction,
            crossoverFunction,
            initializer,
            initialPopulationSize,
            mutationProb = 0.1;
        var pop = List.new();
        initialPopulationSize.do({
            pop.add(initializer.value);
        });
        ("initialized population with size: " + pop.size).postln;
        ^super.newCopyArgs(
            mutationFunction,
            filterFunction,
            crossoverFunction,
            initializer,
            mutationProb,
            pop,
            0);
    }

    next {
        // stream all in this population
        var curr;
        if (currMember == 0, {
            this.nextEpoch;
            ("next generation size: " + population.size).postln;
        });
        curr = population.at(currMember);
        currMember = (currMember + 1) % population.size;
        ^curr;
    }

    nextEpoch {
        // create offspring from the population
        var nextGeneration = List.new;
        (4.rand + 1).do({
            population.scramble.pairsDo({
                arg left, right;
                var child = crossoverFunction.value(left, right);
                child = this.mutate(child);
                if (filterFunction.value(child), {
                    nextGeneration.add(child);
                });
            });
        });
        population = nextGeneration;
    }

    mutate {
        arg child;
        if (mutationProb.coin, {
            ^mutationFunction.value(child);
        }, {
            ^child;
        });
    }
}