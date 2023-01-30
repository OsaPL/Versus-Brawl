
// This for some reason tanks the performance if used each frame, in a workshop located mod.
// NOTE: Remember to use some kind of check, to not call this each frame!
// Example: if(previousPath != newPath){ previousPath = newPath; return FileExistsWithType(newPath); }

bool FileExistsWithType(string path, string extension = ".xml"){

    int extesionLength = extension.length();
    if(path.substr(path.length()-extesionLength, extesionLength) != extension){
        // Path doesnt contain extension
        return false;
    }
    else{
        return FileExists(path);
    }
}