/*
 * Main.vala
 *
 * Copyright 2017 Tony George <teejeetech@gmail.com>
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

using GLib;
using Gee;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.System;
using TeeJee.ProcessHelper;
using TeeJee.Misc;

public Main App;
public const string AppName = "Sanity Installer";
public const string AppShortName = "sanity";
public const string AppVersion = "17.10";
public const int CliVersion = 2;
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejeetech@gmail.com";

const string GETTEXT_PACKAGE = "";
const string LOCALE_DIR = "/usr/share/locale";

extern void exit(int exit_code);

public class Main : GLib.Object{
	
	public Gee.HashMap<string,string> available = new Gee.HashMap<string,string>();
	public Gee.HashMap<string,string> installed = new Gee.HashMap<string,string>();

	public string program_path = "";
	public string base_path = "";
	public string out_path = "";
	public string command = "";
	
	public string app_name = "";
	public string pkg_arch = "";
	public string sys_arch = "";
	public string exec_name = "";
	public string exec_line = "";

	public string sys_type = "";
	public string sys_name = "";
	public string pkg_manager = "";

	public Gee.ArrayList<string> deps_generic = new Gee.ArrayList<string>();
	public Gee.ArrayList<string> deps_debian = new Gee.ArrayList<string>();
	public Gee.ArrayList<string> deps_redhat = new Gee.ArrayList<string>();
	public Gee.ArrayList<string> deps_arch = new Gee.ArrayList<string>();

	public Gee.ArrayList<string> deps_install = new Gee.ArrayList<string>();
	public Gee.ArrayList<string> deps_missing = new Gee.ArrayList<string>();


	public Gee.ArrayList<string> files = new Gee.ArrayList<string>();
	public Gee.ArrayList<string> dirs = new Gee.ArrayList<string>();

	public string install_list = "";
	
	public bool no_prompt = false;
	
	public AppLock app_lock;
	
	public static int main (string[] args) {

		set_locale();

		init_tmp(AppShortName);

		App = new Main(args);

		return 0;
	}

	private static void set_locale(){
		
		log_debug("setting locale...");
		Intl.setlocale(GLib.LocaleCategory.MESSAGES, "polo");
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);
	}

	public Main(string[] args){

		log_debug("Main()");
		
		get_program_path();

		sys_arch = get_sys_arch();

		//check_dependencies();

		//lock_app();

		parse_arguments(args);
	}

	public void get_program_path(){

		log_debug("get_program_path()");
		
		try{
			program_path = GLib.FileUtils.read_link("/proc/self/exe");
			program_path = file_parent(program_path);
		}
		catch(Error e){
			log_error(e.message);
			log_error("Failed to find installer directory path");
			exit(1);
		}
	}

	public void check_admin_access(){

		log_debug("check_admin_access()");
		
		if (!user_is_admin()){
			
			log_error(_("Admin access required for installing files and packages"));
			log_error(_("Run as root; or use 'sudo' or 'pkexec'"));
			exit(1);
		}
	}
	
	public void check_dependencies(){

		log_debug("check_dependencies()");
		
		string[] dependencies = { "" };

		string path;
		string msg = "";
		foreach(string cmd_tool in dependencies){
			path = get_cmd_path (cmd_tool);
			if ((path == null) || (path.length == 0)){
				msg += " [x] " + cmd_tool + "\n";
			}
		}

		if (msg.length > 0){
			msg = _("Commands listed below are not available on this system") + ":\n\n" + msg + "\n";
			msg += _("Please install required packages and try running again");
			log_error(msg);
			
			exit(1);
		}
	}

	public void lock_app(){

		log_debug("lock_app()");
		
		app_lock = new AppLock(AppShortName);
		if (!app_lock.create("running")){
			exit(1);
		}
	}

	public bool parse_arguments(string[] args) {

		log_debug("parse_arguments()");

		command = "install";
		
		//parse options
		for (int k = 1; k < args.length; k++) // Oth arg is app path
		{
			switch (args[k].down()) {
				
			case "--version":
				log_msg("%s:%d".printf(AppVersion, CliVersion));
				exit(0);
				break;

			case "-y":
			case "--yes":
				no_prompt = true;
				break;
				
			case "--debug":
				LOG_DEBUG = true;
				break;

			case "--generate":
				command = "generate";
				break;
				
			case "--generate-config":
				command = "generate-config";
				break;

			case "--base-path":
				base_path = args[++k];
				if (!dir_exists(base_path)){
					log_error(_("Path not found") + ": '%s'".printf(base_path));
					exit(1);
				}
				break;

			case "--out-path":
				out_path = args[++k];
				if (!dir_exists(out_path)){
					log_error(_("Path not found") + ": '%s'".printf(out_path));
					exit(1);
				}
				break;

			case "--arch":
				pkg_arch = args[++k];
				if ((pkg_arch != "amd64") && (pkg_arch != "i386")){
					log_error("Invalid argument for --arch: %s".printf(pkg_arch));
					log_error("Expected: amd64, i386");
					exit(1);
				}
				break;
				
			case "--help":
			case "--h":
			case "-h":
				log_msg(help_message());
				return true;

			default:
				// unknown option; show help and exit
				log_error(_("Unknown option") + ": %s".printf(args[k]));
				log_msg(help_message());
				return false;
			}
		}

		switch(command){
		case "generate":
			generate();
			break;
		case "generate-config":
			generate_config();
			break;
		case "install":
			install();
			break;
		}

		return true;
	}

	private string help_message() {
		string msg = "\n" + AppName + " v" + AppVersion + " by %s (%s)".printf(AppAuthor, AppAuthorEmail) + "\n";
		msg += "\n";
		msg += _("Syntax") + ": sanity\n";
		msg += "\n";
		msg += _("Options") + ":\n";
		msg += "\n";	
		msg += "  --generate-config  " + _("Generate sample sanity.config") + "\n";
		msg += "  --h[elp]           " + _("Show all options") + "\n";
		msg += "  --version          " + _("Show app version") + "\n";
		msg += "\n";
		return msg;
	}
	
	private void install(){

		log_debug("install()");

		check_admin_access();
		
		read_config();

		list_files();
		
		install_files();

		bool ok = check_system();

		if (ok){
			
			check_packages();

			install_packages();

			show_final_message();
		}
	}

	private void read_config(){

		log_debug("read_config()");
		
		string config_file = "";

		if (command == "install"){
			config_file = path_combine(program_path, "sanity.config");
		}
		else {
			config_file = path_combine(base_path, "sanity.config");
		}

		log_debug("file: %s".printf(config_file));
		
		if (!file_exists(config_file)){
			log_error("Could not find installer configuration: sanity.config");
			exit(1);
		}

		foreach(string line in file_read(config_file).split("\n")){

			if (line.strip().length == 0) { continue; }
			
			int index = line.index_of(":");
			if (index == -1) {
				log_error("Invalid line in sanity.config");
				log_error("> %s".printf(line));
				exit(1);
			}
			
			string key = line[0:index].strip().down();
			string text = line[index + 1:line.length].strip();
			text = text.split("#")[0].strip(); // remove comments
			
			switch(key){
			case "depends_debian":
				foreach(string name in text.split(" ")){
					if (name.length == 0){ continue; }
					deps_debian.add(name);
				}
				log_debug("depends_debian: %s".printf(text));
				break;
				
			case "depends_arch":
				foreach(string name in text.split(" ")){
					if (name.length == 0){ continue; }
					deps_arch.add(name);
				}
				log_debug("depends_arch: %s".printf(text));
				break;
				
			case "depends_redhat":
				foreach(string name in text.split(" ")){
					if (name.length == 0){ continue; }
					deps_redhat.add(name);
				}
				log_debug("depends_redhat: %s".printf(text));
				break;

			case "depends_generic":
				foreach(string name in text.split(" ")){
					if (name.length == 0){ continue; }
					deps_generic.add(name);
				}
				log_debug("depends_generic: %s".printf(text));
				break;

			case "app_name":
				app_name = text;
				log_debug("app_name: %s".printf(app_name));
				break;

			//case "app_arch":
			//	app_arch = text;
			//	log_debug("app_arch: %s".printf(app_arch));
			//	break;

			case "exec_line":
				exec_line = text;
				log_debug("exec_line: %s".printf(exec_line));
				break;

			case "assume_yes":
				if (text == "1"){
					no_prompt = true;
				}
				else{
					no_prompt = false;
				}
				log_debug("assume_yes: %s".printf(text));
				break;
			}
		}

		if ((deps_debian.size == 0) && (deps_redhat.size == 0) && (deps_arch.size == 0) && (deps_generic.size == 0)){
			log_error("Dependency packages not specified in file sanity.config");
			log_error("Run 'sanity --generate-config' to generate a sample file");
			exit(1);
		}

		if (app_name.length == 0){
			log_error("Missing parameter in sanity.config: %s".printf("app_name"));
			log_error("Run 'sanity --generate-config' to generate a sample file");
			exit(1);
		}

		if (command == "install"){
			
			string arch_file = path_combine(program_path, "arch");
			
			if (file_exists(arch_file)){

				pkg_arch = file_read(arch_file).strip();
				if ((pkg_arch != "amd64") && (pkg_arch != "i386")){
					log_error("Unknown architecture: %s".printf(pkg_arch));
					log_error("Expected: amd64, i386");
					log_error("This application cannot be installed on this system");
					exit(1);
				}

				if ((pkg_arch == "amd64") && (sys_arch != "x86_64")){
					log_error("Incompatible package architecture");
					log_error("Package arch: %s".printf(pkg_arch));
					log_error("System  arch: %s".printf(sys_arch));
					log_error("This package cannot be installed on this system");
					exit(1);
				}
			}
		}

		log_debug("pkg_arch: %s".printf(pkg_arch));
	}

	private string get_sys_arch(){
		string std_out, std_err;
		exec_sync("uname -m", out std_out, out std_err);
		return std_out.strip();
	}

	private void generate_config(){

		log_debug("write_config()");
		
		string txt = "";
		txt += "app_name: My Application v1.0       # software name\n";
		//txt += "app_arch: amd64                     # 'i386' (32-bit) or 'amd64' (64-bit)\n";
		txt += "exec_line: sudo myapp-gtk           # command for starting application (will be displayed to user after install)\n"; 
		txt += "depends_debian:  package1 package2  # dependency package names for Debian distros\n";
		txt += "depends_redhat:  package1 package2  # dependency package names for Redhat distros\n";
		txt += "depends_arch:    package1 package2  # dependency package names for Arch distros \n";
		txt += "depends_generic: package1 package2  # dependency package names displayed to user for unknown distros\n";
		txt += "assume_yes: 0                       # 1 = prompt user before installing dependencies\n";
		txt += "\n";

		if (file_exists("sanity.config")){
			file_move("sanity.config", "sanity.config.bkup");
		}
		
		file_write("sanity.config", txt);
	}

	private void list_files(){
		
		string files_dir = path_combine(program_path, "files");

		if (!dir_exists(files_dir)){
			log_error("Could not find 'files' directory");
			log_error("Nothing to install");
			exit(1);
			return;
		}

		var file = File.new_for_path(files_dir);
		add_files_from_path(file);
	}

	private void add_files_from_path(GLib.File folder){

		FileInfo info;

		try{
			var enumerator = folder.enumerate_children ("%s,%s".printf(FileAttribute.STANDARD_NAME, FileAttribute.STANDARD_TYPE), 0);
			while ((info = enumerator.next_file()) != null) {
				string child_name = info.get_name();
				string child_path = GLib.Path.build_filename(folder.get_path(), child_name);
				log_debug("File: query_children(): found: %s".printf(info.get_name()));

				if (info.get_file_type() == FileType.DIRECTORY){
					dirs.add(child_path);

					var child = File.new_for_path(child_path);
					add_files_from_path(child);
				}
				else{
					files.add(child_path);
				}
			}
		}
		catch (Error e){
			log_error(e.message);
			log_error("Failed to enumerate files for installation");
			exit(1);
		}
	}

	private void install_files(){

		log_msg(string.nfill(78, '='));
		log_msg("Installing files...");
		log_msg(string.nfill(78, '='));

		string files_dir = path_combine(program_path, "files");
		
		foreach(string dir in dirs){
			string target_path = "/" + dir[files_dir.length + 1: dir.length]; 
			Posix.system("install -m 755 -d '%s'".printf(target_path));
			log_msg("%s".printf(target_path));
		}
		
		foreach(string file in files){
			string target_path = "/" + file[files_dir.length + 1: file.length];
			Posix.system("install -m 0755 '%s' '%s'".printf(file, target_path));
			log_msg("%s".printf(target_path));
		}
	}

	private bool check_system(){

		log_msg(string.nfill(78, '='));
		log_msg("Installing dependency packages...");
		log_msg(string.nfill(78, '='));
		
		if (cmd_exists("apt-get")){
			sys_type = "debian";
			pkg_manager = "apt-get";
		}
		else if (cmd_exists("dnf")){
			sys_type = "redhat";
			pkg_manager = "dnf";
		}
		else if (cmd_exists("yum")){
			sys_type = "redhat";
			pkg_manager = "yum";
		}
		else if (cmd_exists("pacman")){
			sys_type = "arch";
			pkg_manager = "pacman";
		}
		else{
			//log_msg(string.nfill(78, '-'));
			log_error("Unknown distribution and package manager");
			log_error("Dependency packages must be installed manually:");
			foreach(string name in deps_generic){
				log_msg("    > %s".printf(name));
			}
			//log_msg(string.nfill(78, '-'));
			return false;
		}

		switch(sys_type){
		case "debian":
			sys_name = "Debian / Ubuntu";
			break;
		case "redhat":
			sys_name = "RedHat / Fedora / Cent OS";
			break;
		case "arch":
			sys_name = "Arch";
			break;
		}

		//log_msg(string.nfill(78, '-'));
		log_msg("Dist Type: %s".printf(sys_name));
		log_msg("Package Manager: %s".printf(pkg_manager));
		//log_msg(string.nfill(78, '-'));

		return true;
	}

	private void check_packages(){

		//log_msg(string.nfill(78, '='));
		//log_msg("Checking installed packages...");
		//log_msg(string.nfill(78, '='));

		log_debug("check_packages()");
		
		switch(pkg_manager){
		case "dnf":
			check_packages_dnf();
			break;
		case "yum":
			check_packages_yum();
			break;
		case "pacman":
			check_packages_pacman();
			break;
		case "apt-get":
			check_packages_apt();
			break;
		}

		log_msg("Installed: %d".printf(installed.size));
		log_msg("Available: %d".printf(available.size));

		check_packages_to_install();
	}

	private void check_packages_dnf(){

		log_debug("check_packages_dnf()");

		installed = new Gee.HashMap<string,string>();
		
		string std_out, std_err;
		exec_sync("dnf list installed", out std_out, out std_err);
		foreach(string line in std_out.split("\n")){
			string[] arr = line.split(" ");
			if (arr.length == 0) { continue; }
			string name = arr[0].strip();
			name = name.split(".")[0]; // remove .x86_64 .noarch etc
			installed[name] = name;
		}

		available = new Gee.HashMap<string,string>();
		
		exec_sync("dnf list available", out std_out, out std_err);
		foreach(string line in std_out.split("\n")){
			string[] arr = line.split(" ");
			if (arr.length == 0) { continue; }
			string name = arr[0].strip();
			name = name.split(".")[0]; // remove .x86_64 .noarch etc
			available[name] = name;
		}
	}

	private void check_packages_yum(){
	
		log_debug("check_packages_yum()");

		installed = new Gee.HashMap<string,string>();
		
		string std_out, std_err;
		exec_sync("yum list installed", out std_out, out std_err);
		foreach(string line in std_out.split("\n")){
			string[] arr = line.split(" ");
			if (arr.length == 0) { continue; }
			string name = arr[0].strip();
			name = name.split(".")[0]; // remove .x86_64 .noarch etc
			installed[name] = name;
		}

		available = new Gee.HashMap<string,string>();
		
		exec_sync("yum list available", out std_out, out std_err);
		foreach(string line in std_out.split("\n")){
			string[] arr = line.split(" ");
			if (arr.length == 0) { continue; }
			string name = arr[0].strip();
			name = name.split(".")[0]; // remove .x86_64 .noarch etc
			available[name] = name;
		}
	}

	private void check_packages_pacman(){

		log_debug("check_packages_pacman()");

		installed = new Gee.HashMap<string,string>();
		
		string std_out, std_err;
		exec_sync("pacman -Qq", out std_out, out std_err);
		foreach(string line in std_out.split("\n")){
			string[] arr = line.split(" ");
			if (arr.length == 0) { continue; }
			string name = arr[0].strip();
			installed[name] = name;
		}

		available = new Gee.HashMap<string,string>();

		exec_sync("pacman -Ssq", out std_out, out std_err);
		foreach(string line in std_out.split("\n")){
			string[] arr = line.split(" ");
			if (arr.length == 0) { continue; }
			string name = arr[0].strip();
			available[name] = name;
		}
	}

	private void check_packages_apt(){

		log_debug("check_packages_apt()");

		installed = new Gee.HashMap<string,string>();
		
		string std_out, std_err;
		exec_sync("dpkg --get-selections", out std_out, out std_err);
		foreach(string line in std_out.split("\n")){
			if (line.contains("deinstall")){ continue; }
			string[] arr = line.split("\t");
			if (arr.length == 0) { continue; }
			string name = arr[0].strip();
			name = name.split(":")[0]; // remove :amd64 :i386 etc
			installed[name] = name;
			//log_debug("installed: '%s'".printf(name));
		}

		available = new Gee.HashMap<string,string>();
		
		exec_sync("apt-cache pkgnames", out std_out, out std_err);
		foreach(string line in std_out.split("\n")){
			string[] arr = line.split("\t");
			if (arr.length == 0) { continue; }
			string name = arr[0].strip();
			name = name.split(":")[0]; // remove :amd64 :i386 etc
			available[name] = name;
			//log_debug("available: '%s'".printf(name));
		}
	}

	private void check_packages_to_install(){

		log_debug("check_packages_to_install()");
		
		var deps_list = deps_generic;

		switch(sys_type){
		case "debian":
			deps_list = deps_debian;
			break;
		case "redhat":
			deps_list = deps_redhat;
			break;
		case "arch":
			deps_list = deps_arch;
			break;
		}

		deps_install = new Gee.ArrayList<string>();
		deps_missing = new Gee.ArrayList<string>();
		
		foreach(string name in deps_list){

			if (installed.has_key(name)){
				log_debug("installed: %s".printf(name));
				continue;
			}
			
			if (!available.has_key(name)){
				log_debug("missing: %s".printf(name));
				deps_missing.add(name);
				continue;
			}

			deps_install.add(name);
			deps_missing.add(name); // add to missing as well
			log_debug("pending: %s".printf(name));
		}

		log_debug("deps_install: %d".printf(deps_install.size));

		if (deps_install.size == 0){
			return;
		}
		
		string list = "";
		foreach(string name in deps_install){
			if (list.length > 0){ list += " "; }
			list += name;
		}
		install_list = list;
	}

	private void install_packages(){

		if (deps_install.size == 0){
			log_msg("Nothing to install");
			return;
		}

		switch(pkg_manager){
		case "dnf":
			install_packages_dnf();
			break;
		case "yum":
			install_packages_yum();
			break;
		case "pacman":
			install_packages_pacman();
			break;
		case "apt-get":
			install_packages_apt();
			break;
		}

		check_packages();
	}

	private void install_packages_dnf(){

		log_debug("install_packages_dnf()");
		
		if (install_list.length == 0){ return; }
		
		Posix.system("dnf install %s".printf(install_list));
	}

	private void install_packages_yum(){

		log_debug("install_packages_yum()");
		
		if (install_list.length == 0){ return; }
		
		Posix.system("yum install %s".printf(install_list));
	}

	private void install_packages_pacman(){

		log_debug("install_packages_pacman()");

		if (install_list.length == 0){ return; }
		
		Posix.system("pacman -S %s".printf(install_list));
	}

	private void install_packages_apt(){

		log_debug("install_packages_apt()");
		
		if (install_list.length == 0){ return; }
		
		Posix.system("apt-get install %s".printf(install_list));
	}

	private void show_final_message(){

		log_msg(string.nfill(78, '='));
		log_msg("Installation completed");
		log_msg(string.nfill(78, '='));

		if (deps_missing.size > 0){
			//stderr.printf("%s\n".printf(string.nfill(78, '-')));
			stderr.printf("Following packages could not be installed. Please install these manually:\n");
			foreach(string name in deps_missing){
				stderr.printf(" > %s\n".printf(name));
			}
			stderr.printf("%s\n".printf(string.nfill(78, '-')));
			stderr.flush();
		}

		//stderr.printf("%s\n".printf(string.nfill(78, '-')));
		log_msg("Start the application using shortcut in Applications Menu");
		log_msg("Or execute the command: %s".printf(exec_line));
		log_msg("%s".printf(string.nfill(78, '-')));
		//log_msg("");
	}

	// -------------------------------------

	private void generate(){

		log_debug("generate()");

		if (base_path.length == 0){
			log_error("Base path not specified: --base-path <path>");
			exit(1);
		}

		if (out_path.length == 0){
			log_error("Output path not specified: --out-path <path>");
			exit(1);
		}

		if (pkg_arch.length == 0){
			log_error("Package architecture not specified: --arch {amd64,i386}");
			exit(1);
		}
		
		read_config();

		string sanity_i386 = path_combine("/usr/share/sanity/files", "sanity.i386");
		string sanity_amd64 = path_combine("/usr/share/sanity/files", "sanity.amd64");
		string lib_i386 = path_combine("/usr/share/sanity/files", "lib32");
		string lib_amd64 = path_combine("/usr/share/sanity/files", "lib64");
		string bootstrapper = path_combine("/usr/share/sanity/files", "install.sh");
		
		string sanity_i386_temp = path_combine(base_path, "sanity.i386");
		string sanity_amd64_temp = path_combine(base_path, "sanity.amd64");
		string lib_i386_temp = path_combine(base_path, "lib32");
		string lib_amd64_temp = path_combine(base_path, "lib64");
		string bootstrapper_temp = path_combine(base_path, "install.sh");
		string arch_temp = path_combine(base_path, "arch");
		
		file_copy(sanity_i386, sanity_i386_temp);
		chmod(sanity_i386_temp, "a+x");
		
		file_copy(sanity_amd64, sanity_amd64_temp);
		chmod(sanity_amd64_temp, "a+x");
		
		file_copy(bootstrapper, bootstrapper_temp);
		chmod(bootstrapper_temp, "a+x");

		Posix.system("mkdir -p %s".printf(lib_i386_temp));
		Posix.system("cp -vf %s/* %s/".printf(lib_i386, lib_i386_temp));
		
		Posix.system("mkdir -p %s".printf(lib_amd64_temp));
		Posix.system("cp -vf %s/* %s/".printf(lib_amd64, lib_amd64_temp));
		
		file_write(arch_temp, pkg_arch);

		string out_file = path_combine(out_path, "%s-%s.run".printf(app_name.down().replace(" ","-"), pkg_arch));

		string cmd = "makeself '%s' '%s' \"%s (%s)\" ./install.sh ".printf(
			escape_single_quote(base_path), escape_single_quote(out_file), app_name, pkg_arch);

		log_debug(cmd);
		
		Posix.system(cmd);

		file_delete(sanity_i386_temp);
		file_delete(sanity_amd64_temp);
		file_delete(bootstrapper_temp);
		file_delete(arch_temp);
	}
}





