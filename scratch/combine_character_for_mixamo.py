import bpy
import os
import sys

# Absolute workspace paths
WORKSPACE_DIR = r"c:\Users\User\Documents\THRESHOLD"
BODY_PATH = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\body\body_torso_m.gltf")
HEAD_PATH = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\heads\head_head_001.gltf")
HAIR_PATH = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\hair\hair_000.gltf")
OUTPUT_GLTF = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.gltf")
OUTPUT_OBJ = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.obj")

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def import_and_transform_gltf(gltf_path, location=(0,0,0), rotation=(0,0,0), scale=(1,1,1)):
    if not os.path.exists(gltf_path):
        print(f"File not found: {gltf_path}")
        return []
    
    # Track existing objects before import
    before_objs = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=gltf_path)
    after_objs = set(bpy.data.objects)
    new_objs = list(after_objs - before_objs)
    
    # Apply transforms to root objects
    for obj in new_objs:
        if obj.parent is None:
            obj.location = location
            obj.rotation_euler = rotation
            obj.scale = scale
            
    return new_objs

def main():
    print("Clearing scene...")
    clear_scene()
    
    print("Importing Body...")
    body_objs = import_and_transform_gltf(BODY_PATH, location=(0, 0, 0), scale=(2.5, 2.5, 2.5))
    
    print("Importing Head...")
    head_objs = import_and_transform_gltf(HEAD_PATH, location=(0, 1.155, 0), scale=(1.0, 1.0, 1.0))
    
    print("Importing Hair...")
    hair_objs = import_and_transform_gltf(HAIR_PATH, location=(0, 1.605, 0), scale=(6.6, 6.6, 6.6))
    
    # Select all meshes
    bpy.ops.object.select_all(action='DESELECT')
    mesh_objs = []
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            obj.select_set(True)
            mesh_objs.append(obj)
            
    if mesh_objs:
        bpy.context.view_layer.objects.active = mesh_objs[0]
        # Join meshes into one single mesh
        bpy.ops.object.join()
        combined_obj = bpy.context.active_object
        combined_obj.name = "MixamoCharacterBase"
        
        # Apply transforms so scale is (1,1,1) and location (0,0,0)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        print("Joined meshes into single object:", combined_obj.name)
        
        # Export as GLB / GLTF
        OUTPUT_GLB = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.glb")
        bpy.ops.export_scene.gltf(filepath=OUTPUT_GLB, export_format='GLB')
        print(f"Successfully exported Mixamo-ready GLB: {OUTPUT_GLB}")
        
        # Export as OBJ as well for maximum Mixamo compatibility
        try:
            bpy.ops.wm.obj_export(filepath=OUTPUT_OBJ)
            print(f"Successfully exported Mixamo-ready OBJ: {OUTPUT_OBJ}")
        except Exception as e:
            print(f"OBJ export notice: {e}")
    else:
        print("No meshes found to combine!")

if __name__ == "__main__":
    main()
