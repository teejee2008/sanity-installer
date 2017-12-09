
/*
 * TeeJee.ProcessHelper.vala
 *
 * Copyright 2016 Tony George <teejeetech@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 *
 */
 
namespace TeeJee.ProcessHelper{
	
	using TeeJee.Logging;
	using TeeJee.FileSystem;
	using TeeJee.Misc;

	public string TEMP_DIR;
	
	/* Convenience functions for executing commands and managing processes */

	// execute process -------------------------------------------
	
    public static void init_tmp(string subdir_name){
		
		string std_out, std_err;

		TEMP_DIR = Environment.get_tmp_dir() + "/" + subdir_name + "/" + random_string();
		dir_create(TEMP_DIR);

		exec_sync("echo 'ok'",out std_out,out std_err);
		
		if ((std_out == null) || (std_out.strip() != "ok")){
			
			TEMP_DIR = Environment.get_home_dir() + "/.temp/" + subdir_name + "/" + random_string();
			exec_sync("rm -rf '%s'".printf(TEMP_DIR), null, null);
			dir_create(TEMP_DIR);
		}

		//log_debug("TEMP_DIR=" + TEMP_DIR);
	}

	public string create_temp_subdir(){
		
		var temp = "%s/%s".printf(TEMP_DIR, random_string());
		dir_create(temp);
		return temp;
	}
	
	public int exec_sync (string cmd, out string? std_out, out string? std_err){

		/* Executes single command synchronously.
		 * Pipes and multiple commands are not supported.
		 * std_out, std_err can be null. Output will be written to terminal if null. */

		try {
			int status;
			Process.spawn_command_line_sync(cmd, out std_out, out std_err, out status);
	        return status;
		}
		catch (Error e){
	        log_error (e.message);
	        return -1;
	    }
	}

	public string get_temp_file_path(){

		/* Generates temporary file path */

		return TEMP_DIR + "/" + timestamp_numeric() + (new Rand()).next_int().to_string();
	}

	// find process ----------------------------------------------
	
	// dep: which
	public string get_cmd_path (string cmd_tool){

		/* Returns the full path to a command */

		try {
			int exitCode;
			string stdout, stderr;
			Process.spawn_command_line_sync("which " + cmd_tool, out stdout, out stderr, out exitCode);
	        return stdout;
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}

	public bool cmd_exists(string cmd_tool){
		
		string path = get_cmd_path (cmd_tool);
		
		if ((path == null) || (path.length == 0)){
			return false;
		}
		else{
			return true;
		}
	}
}
