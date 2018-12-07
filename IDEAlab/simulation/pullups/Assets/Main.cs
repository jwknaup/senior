using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Main : MonoBehaviour {

    CLI cli = new CLI();
    File file = new File();
    LegInverted leg = new LegInverted();

    // Use this for initialization
    void Start () {

        cli.getArgs();

        string path = "output.csv";
        file.open(path);

        leg.setPhysConstants();

        float drag = 6.1755f;// float.Parse(cli.getArg(2));
        float angularDrag = 0;// float.Parse(cli.getArg(3));
        float rigidSpring = 14.0224f * leg.torqueScaleFactor;// float.Parse(cli.getArg(4));
        float rigidDamper = 0;// float.Parse(cli.getArg(5));
        float jointSpring = 0.0229183f*leg.torqueScaleFactor;//float.Parse(cli.getArg(6));
        float jointDamper = 0;// float.Parse(cli.getArg(7));
        float length = 8;// float.Parse(cli.getArg(3));

        float width = 1, thickness = 0.3f;
        //float length = 8;//4, 8, 12;
        leg.setDimensions(length, width, thickness);
        leg.setMotorConstants(75);
        leg.setMasses(0.72f, 1.25f);
        leg.setDragConstants(drag, angularDrag);
        leg.setSpringConstants(rigidSpring, rigidDamper, jointSpring, jointDamper);

        leg.createGround();
        leg.createLeg();

        startHeight = leg.topBody.position.y;
    }

    float height = -100, startHeight, maxHeight;
    void Update () {
        height = startHeight - leg.topBody.position.y;
        string data = string.Format("{0}, {1}", Time.time, height/100f);
        file.writeLine(data);
        if (Time.time > 0.09 && height < maxHeight)
        {
            file.close();
            PlayerControl.close();
        }
        if(height > maxHeight)
        {
            maxHeight = height;
        }
    }
}
