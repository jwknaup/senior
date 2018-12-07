using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Runtime.InteropServices;

public class CLI
{
    private string[] args;

    public string[] getArgs()
    {
        args = System.Environment.GetCommandLineArgs();
        return args;
    }

    public string getArg(int argNum)
    {
        return args[argNum];
    }
}
