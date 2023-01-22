import sys
import bpy

argv = sys.argv

# First frame to export
frame_start = int(argv[argv.index("--start-frame") + 1])
print(frame_start)

# Last frame to export
frame_end = int(argv[argv.index("--end-frame") + 1])
print(frame_end)

# Name of the mesh
meshName = argv[argv.index("--mesh-name") + 1]
print(meshName)

# Filename, path must already exist!
exportfilepath = argv[argv.index("--export-file-path") + 1]
print(exportfilepath)

# TODO! This doesnt work if .blend is not currently in object mode
# Try: bpy.ops.object.mode_set(mode = 'OBJECT')?

# Select the mesh first
# ob = bpy.context.scene.objects[meshName] # Get the object
# bpy.ops.object.select_all(action='DESELECT') # Deselect all objects
# bpy.context.view_layer.objects.active = ob # Make the mesh the active object 
# ob.select_set(True)

# Go through frame range
for f in range(frame_start, frame_end + 1):
    bpy.context.scene.frame_set(f) # Change frame
    bpy.ops.export_scene.obj( # Export to .obj 
        filepath= exportfilepath + "/" + meshName + ("-f%04d.obj" % (f)),
        use_materials=False,
        use_selection=True
    )