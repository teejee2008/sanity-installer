# Sanity Installer

A command-line tool for generating 32-bit and 64-bit binary installers (*.run) for software. Installer is packaged using [makeself]([http://makeself.io](http://makeself.io/)) with gzip compression. It can install files, dependency packages, and execute pre/post-install scripts. Supports distributions based on Debian (apt), Arch (pacman) and Fedora (yum).

# Usage

1. Set up [pbuilder](https://pbuilder.alioth.debian.org/) on an Ubuntu-based distribution
2. Set up a build environment for building Vala files


  ```
  sudo apt install gdebi aptitude curl pigz pv diffuse geany geany-plugins valac build-essential pbuilder autotools-dev automake libgtk-3-dev libgee-0.8-dev libsoup2.4-dev libjson-glib-dev makeself
  ```

3. Build and install Sanity by running ``sh build-stubs.sh && make all && sudo make install-all`` . 
4. Check installed version: ``sanity --version``
5. Create a project folder `<basepath>` 
6. Copy files for installation to path `<basepath>/files`. Contents of this directory will be copied to filesystem root `/` by the installer.
7. Create text file named `sanity.config` in `basepath`.  A sample file is shown below:


```
app_name: Aptik
depends_debian:  libgee-0.8-2 libjson-glib-1.0-0 rsync
depends_redhat:  libgee json-glib rsync
depends_arch:    libgee json-glib rsync
depends_generic: libgee json-glib rsync
assume_yes: 0
exec_line: pkexec aptik
```

8. (Optional) Place pre-install and post-install scripts in `<basepath>`. Scripts should be named `preinst.sh` and `postinst.sh` .

9. Generate installers using syntax:

   ```
   sanity --generate --base-path <basepath> --out-path ./ --arch i386
   sanity --generate --base-path <basepath> --out-path ./ --arch amd64
   ```

   ​

   ​


