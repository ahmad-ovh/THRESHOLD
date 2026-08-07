import bpy
import os
import mathutils

WORKSPACE_DIR = r"c:\Users\User\Documents\THRESHOLD"
BODY_PATH = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\body\body_torso_m.gltf")
HEAD_PATH = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\heads\head_head_001.gltf")

OUTPUT_BLEND = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_character_aligned.blend")
OUTPUT_GLB = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.glb")
OUTPUT_OBJ = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\mixamo_ready_character.obj")

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def import_gltf_part(name, filepath):
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return None
    
    before_objs = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=filepath)
    after_objs = set(bpy.data.objects)
    imported = list(after_objs - before_objs)
    
    mesh_objs = [o for o in imported if o.type == 'MESH']
    if not mesh_objs:
        return None
        
    for o in mesh_objs:
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
        
    for o in imported:
        if o.type != 'MESH':
            bpy.data.objects.remove(o, do_unlink=True)
            
    if len(mesh_objs) > 1:
        bpy.ops.object.select_all(action='DESELECT')
        for o in mesh_objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = mesh_objs[0]
        bpy.ops.object.join()
        main_obj = bpy.context.active_object
    else:
        main_obj = mesh_objs[0]
        
    main_obj.name = name
    return main_obj

def main():
    clear_scene()
    
    # 1. Import Body
    body = import_gltf_part("Body_Mesh", BODY_PATH)
    if body:
        body.scale = (2.5, 2.5, 2.5)
        bpy.context.view_layer.objects.active = body
        body.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        
        # Center body (Feet at Z=0)
        bbox = [body.matrix_world @ mathutils.Vector(corner) for corner in body.bound_box]
        min_x = min(v.x for v in bbox)
        max_x = max(v.x for v in bbox)
        min_y = min(v.y for v in bbox)
        max_y = max(v.y for v in bbox)
        min_z = min(v.z for v in bbox)
        
        body.location = (-(min_x + max_x) / 2.0, -(min_y + max_y) / 2.0, -min_z)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # 2. Import Head
    head = import_gltf_part("Head_Mesh", HEAD_PATH)
    if head:
        # Scale head to match body proportion (scale 2.5)
        head.scale = (2.5, 2.5, 2.5)
        bpy.context.view_layer.objects.active = head
        head.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        
        # Set origin of Head_Mesh to its bounding box center
        bpy.ops.object.origin_set(type='ORIGIN_GEOMETRY', center='BOUNDS')
        
        # Position Head at neck top: X=0, Y=0, Z=1.65m
        head.location = (0.0, 0.0, 1.65)
        # DO NOT call transform_apply so head.location stays (0.0, 0.0, 1.65) in Blender!

    # Deselect all
    bpy.ops.object.select_all(action='DESELECT')
    
    # Save .blend file
    bpy.ops.wm.save_as_mainfile(filepath=OUTPUT_BLEND)
    print(f"Saved Blend file with visible Head at Z=1.65m: {OUTPUT_BLEND}")

    # Select both for export
    for o in [body, head]:
        if o:
            o.select_set(True)
            
    bpy.ops.export_scene.gltf(filepath=OUTPUT_GLB, export_format='GLB')
    try:
        bpy.ops.wm.obj_export(filepath=OUTPUT_OBJ)
    except Exception as e:
        print("OBJ Export:", e)
        
    print("Exported GLB & OBJ!")

if __name__ == "__main__":
    main()
