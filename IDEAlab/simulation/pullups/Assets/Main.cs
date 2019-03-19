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

        leg.setPhysConstants(1, 1, -01f);

        float drag = 0;// float.Parse(cli.getArg(2)) / 1000; // 24711, 14721, 2799
        float angularDrag = 460;// float.Parse(cli.getArg(2))/10;//460 float.Parse(cli.getArg(3));
        float rigidSpring = 14.0224f * leg.torqueScaleFactor;// float.Parse(cli.getArg(4));
        float rigidDamper = 0;// float.Parse(cli.getArg(5));
        float jointSpring = 0.0229183f*leg.torqueScaleFactor;//float.Parse(cli.getArg(6));
        float jointDamper = 0;// 2500/ 10000000;// float.Parse(cli.getArg(2)) / 10000000;// float.Parse(cli.getArg(7));
        float length = float.Parse(cli.getArg(3)); //2490, 6446, 2783
        float gearRatio = float.Parse(cli.getArg(4));

        float width = 0.01f, thickness = 0.002f;
        //float length = 8;//4, 8, 12;
        leg.setDimensions(length, width, thickness, 10);
        leg.setMotorConstants(gearRatio, -1);
        leg.setMasses(0.0369f, 1520);
        leg.setDragConstants(drag, angularDrag);
        leg.setSpringConstants(rigidSpring, rigidDamper, jointSpring, jointDamper);

        leg.createGround();
        leg.createLeg(true);

        startHeight = leg.ground.transform.position.y;// leg.topBody.position.y; //leg.ground.transform.position.y
    }

    float max_time = 0.9f, threshold = 0.01f;
    float height, startHeight, maxHeight;
    void Update () {
        height = Mathf.Abs(startHeight - leg.topBody.position.y);
        string data = string.Format("{0}, {1}", Time.time, height/leg.lengthScaleFactor);
        file.writeLine(data);
        if ((Time.time > 0.09 && height < maxHeight - threshold) || Time.time > max_time)
        {
            file.close();
            PlayerControl.close();
        }
        if (height > maxHeight)
        {
            maxHeight = height;
        }
    }
}
