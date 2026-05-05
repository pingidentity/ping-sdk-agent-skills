"""
Custom claudelint rules for Ping Identity Agent Skills.

Validates:
1. Root and plugin-level .claude-plugin/plugin.json files
2. Each skill directory contains SKILL.md
3. Skill subdirectories only contain assets, references, and scripts folders
"""

import os
from pathlib import Path


def validate_root_plugin_json(config):
    """Ensure root .claude-plugin/plugin.json exists."""
    errors = []
    root_plugin_json = Path(".claude-plugin/plugin.json")
    
    if not root_plugin_json.exists():
        errors.append({
            "path": str(root_plugin_json),
            "severity": "error",
            "message": "Missing root .claude-plugin/plugin.json file. Required at repository root."
        })
    
    return errors


def validate_plugin_level_plugin_json(config):
    """Ensure each plugin has .claude-plugin/plugin.json."""
    errors = []
    plugins_dir = Path("plugins")
    
    if not plugins_dir.exists():
        return errors
    
    for plugin_dir in plugins_dir.iterdir():
        if not plugin_dir.is_dir() or plugin_dir.name.startswith("."):
            continue
        
        plugin_json = plugin_dir / ".claude-plugin" / "plugin.json"
        if not plugin_json.exists():
            errors.append({
                "path": str(plugin_json),
                "severity": "error",
                "message": f"Missing .claude-plugin/plugin.json in plugin '{plugin_dir.name}'. Required at plugin level."
            })
    
    return errors


def validate_skill_markdown_files(config):
    """Ensure each skill directory contains SKILL.md."""
    errors = []
    plugins_dir = Path("plugins")
    
    if not plugins_dir.exists():
        return errors
    
    for plugin_dir in plugins_dir.iterdir():
        if not plugin_dir.is_dir() or plugin_dir.name.startswith("."):
            continue
        
        skills_dir = plugin_dir / "skills"
        if not skills_dir.exists():
            continue
        
        for skill_dir in skills_dir.iterdir():
            if not skill_dir.is_dir() or skill_dir.name.startswith("."):
                continue
            
            skill_md = skill_dir / "SKILL.md"
            if not skill_md.exists():
                errors.append({
                    "path": str(skill_md),
                    "severity": "error",
                    "message": f"Missing SKILL.md in skill '{skill_dir.name}'. Required in each skill directory."
                })
    
    return errors


def validate_skill_subdirectories(config):
    """Ensure skill subdirectories only contain assets, references, and scripts."""
    errors = []
    allowed_dirs = {"assets", "references", "scripts"}
    plugins_dir = Path("plugins")
    
    if not plugins_dir.exists():
        return errors
    
    for plugin_dir in plugins_dir.iterdir():
        if not plugin_dir.is_dir() or plugin_dir.name.startswith("."):
            continue
        
        skills_dir = plugin_dir / "skills"
        if not skills_dir.exists():
            continue
        
        for skill_dir in skills_dir.iterdir():
            if not skill_dir.is_dir() or skill_dir.name.startswith("."):
                continue
            
            for item in skill_dir.iterdir():
                # Skip files (like SKILL.md)
                if item.is_file():
                    continue
                
                # Skip hidden directories
                if item.name.startswith("."):
                    continue
                
                # Check if directory name is allowed
                if item.name not in allowed_dirs:
                    errors.append({
                        "path": str(item),
                        "severity": "error",
                        "message": f"Unexpected directory '{item.name}' in skill '{skill_dir.name}'. "
                                   f"Only 'assets', 'references', and 'scripts' directories are allowed."
                    })
    
    return errors


# Register custom rules
def register_rules():
    """Return a list of custom rule functions."""
    return [
        validate_root_plugin_json,
        validate_plugin_level_plugin_json,
        validate_skill_markdown_files,
        validate_skill_subdirectories,
    ]
