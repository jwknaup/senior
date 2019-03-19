using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class File {

    private StreamWriter writer;

    public void open(string path)
    {
       writer = new StreamWriter(path, false);
    }

    public void writeLine(string text)
    {
        writer.WriteLine(text);
    }

    public void close()
    {
        writer.Flush();
        writer.Close();
    }
	
}
