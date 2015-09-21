using System;
using System.Collections.Generic;
using System.Diagnostics;
//using System.Drawing;
using System.Threading;
using System.ComponentModel;
using System.Windows.Forms;
using System.IO;

using SharpDX;
using SharpDX.D3DCompiler;
using SharpDX.Direct3D;
using SharpDX.Direct3D11;

using Buffer = SharpDX.Direct3D11.Buffer;
using Device = SharpDX.Direct3D11.Device;

class dumptech
{
    public static void Main(string[] args)
    {
        Device device;
        Effect effect;

        device = new Device(DriverType.Hardware, DeviceCreationFlags.None);

        if (args.Length < 1)
        {
            Console.WriteLine("Usage: dumptech.exe <effect file>");
            return;
        }

        string effect_file = args[0];

        if (! File.Exists(effect_file))
        {
            Console.WriteLine("File not found: " + effect_file);
            return;
        }
        try
        {
            var shader_bytecode = ShaderBytecode.FromFile(effect_file);
            effect = new Effect(device, shader_bytecode);
        }
        catch (SharpDX.CompilationException e)
        {
            Console.WriteLine(e.Message + ": " + effect_file);
            return;
        }

        //Console.WriteLine("technique count {0}", effect.Description.TechniqueCount);
        for (int i = 0; i < effect.Description.TechniqueCount; i++)
        {
            var technique = effect.GetTechniqueByIndex(i);
            Console.WriteLine("{0}\t{1}", i, technique.Description.Name);
        }

        if (effect != null)
            effect.Dispose();
        if (device != null)
            device.Dispose();
    }
}
