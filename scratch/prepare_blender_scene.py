import bpy
import os
import mathutils

WORKSPACE_DIR = r"c:\Users\User\Documents\THRESHOLD"
BODY_PATH = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\body\body_torso_m.gltf")
HEAD_PATH = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\heads\head_head_001.gltf")
HAIR_PATH = os.path.join(WORKSPACE_DIR, r"client\assets\character_models\hair\hair_000.gltf")

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
        
    # Unparent meshes and keep world transform
    for o in mesh_objs:
        bpy.context.view_layer.objects.active = o
        o.select_set(True)
        bpy.ops.object.parent_clear(type='CLEAR_KEEP_TRANSFORM')
        
    # Delete non-mesh parent nodes
    for o in imported:
        if o.type != 'MESH':
            bpy.data.objects.remove(o, do_unlink=True)
            
    # If multiple meshes imported for one part, join them
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
        # Scale body by 2.5
        body.scale = (2.5, 2.5, 2.5)
        bpy.context.view_layer.objects.active = body
        body.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        
        # Center body at origin (0,0,0)
        bbox = [body.matrix_world @ mathutils.Vector(corner) for corner in body.bound_box]
        min_x = min(v.x for v in bbox)
        max_x = max(v.x for v in bbox)
        min_y = min(v.y for v in bbox)
        max_y = max(v.y for v in bbox)
        min_z = min(v.z for v in bbox)
        center_x = (min_x + max_x) / 2.0
        center_y = (min_y + max_y) / 2.0
        
        body.location.x -= center_x
        body.location.y -= center_y
        body.location.z -= min_z  # Feet at Z=0
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # 2. Import Head
    head = import_gltf_part("Head_Mesh", HEAD_PATH)
    if head:
        # Rotate head if needed and align on top of body neck (~Z=1.65)
        head.rotation_euler = (0, 0, 0)
        bpy.context.view_layer.objects.active = head
        head.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        
        bbox = [head.matrix_world @ mathutils.Vector(corner) for corner in head.bound_box]
        center_x = (min(v.x for v in bbox) + max(v.x for v in bbox)) / 2.0
        center_y = (min(v.y for v in bbox) + max(v.y for v in bbox)) / 2.0
        min_z = min(v.z for v in bbox)
        
        # Align Head to center X=0, Y=0, and sit at neck height Z=1.60
        head.location = (-center_x, -center_y, 1.60 - min_z)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # 3. Import Hair
    hair = import_gltf_part("Hair_Mesh", HAIR_PATH)
    if hair:
        # Hair original mesh faces down (-Z), rotate +90deg on X to face forward/up
        hair.rotation_euler = (1.5708, 0, 0)
        hair.scale = (6.6, 6.6, 6.6)
        bpy.context.view_layer.objects.active = hair
        hair.select_set(True)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        
        bbox = [hair.matrix_world @ mathutils.Vector(corner) for corner in hair.bound_box]
        center_x = (min(v.x for v in bbox) + max(v.x for v in bbox)) / 2.0
        center_y = (min(v.y for v in bbox) + max(v.y for v in bbox)) / 2.0
        min_z = min(v.z for v in bbox)
        
        # Align Hair onto top of head (~Z=1.75)
        hair.location = (-center_x, -center_y, 1.75 - min_z)
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

    # Deselect all
    bpy.ops.object.select_all(action='DESELECT')
    
    # Save .blend file so user can open directly in Blender
    bpy.ops.wm.save_as_mainfile(filepath=OUTPUT_BLEND)
    print(f"Saved separate-objects Blend file: {OUTPUT_BLEND}")

    # Join for Mixamo export
    for o in [body, head, hair]:
        if o:
            o.select_set(True)
    if body:
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.join()
        combined = bpy.context.active_object
        combined.name = "MixamoCharacterCombined"
        
        bpy.ops.export_scene.gltf(filepath=OUTPUT_GLB, export_format='GLB')
        try:
            bpy.ops.wm.obj_export(filepath=OUTPUT_OBJ)
        except Exception as e:
            print("OBJ Export:", e)
        print("Exported aligned GLB & OBJ!")

if __name__ == "__main__":
    main()
