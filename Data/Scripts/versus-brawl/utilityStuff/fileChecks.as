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