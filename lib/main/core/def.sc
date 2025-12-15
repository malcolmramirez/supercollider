Def {
    var name;

    *new { |name|
        ^super.newCopyArgs(name);
    }

    doesNotUnderstand { |selector ...args|
        var node, selectorString, ndefName;

        node = args[0];
        if (args.size > 1) {
            Error("Only one arg allowed!").throw;
        };

        selectorString = selector.asString;
        ndefName = (name.asString ++ "_" ++ selectorString);
        ndefName = (ndefName ++ "_" ++ ndefName.hash).asSymbol;
        
        if (node.isKindOf(String)) {
            var trig = selectorString.endsWith("_t");
            if (trig) {
                selectorString = selectorString[0..(selectorString.size-3)];
            };
            node = SP(ndefName).trig_(trig).pat(node);
        };
        selector = selectorString.asSymbol;
        Ndef(name).map(selector, node)
    }

    play {
        Ndef(name).play;
    }
}
