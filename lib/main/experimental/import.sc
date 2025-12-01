Import {

    *new {
        arg file, s = Server.default;
        var parent = PathName(thisProcess.nowExecutingPath).parentPath;
        var path = (parent +/+ file);
        path.load;
        s.sync;
    }
}