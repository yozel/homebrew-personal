require 'formula'

# print avr-gcc's builtin include paths
# `avr-gcc -print-prog-name=cc1plus` -v

class AvrGcc < Formula
  homepage 'http://gcc.gnu.org'
  url 'http://ftp.gnu.org/gnu/gcc/gcc-4.8.2/gcc-4.8.2.tar.bz2'
  sha1 '810fb70bd721e1d9f446b6503afe0a9088b62986'

  depends_on 'avr-binutils'
  depends_on 'gmp'
  depends_on 'libmpc'
  depends_on 'mpfr'

  option 'with-cxx', 'build with support for C++'

  resource 'avr-libc' do
    url 'http://download.savannah.gnu.org/releases/avr-libc/avr-libc-1.8.0.tar.bz2'
    sha1 '2e3815221be8e22f5f2c07b922ce92ecfa85bade'
  end

  resource 'avr-libc-manpages' do
    url 'http://download.savannah.gnu.org/releases/avr-libc/avr-libc-manpages-1.8.0.tar.bz2'
    sha1 '586cf60bb9d2b67498b73b38b546f7b4620dc86c'
  end

  resource 'avr-libc-html' do
    url 'http://download.savannah.gnu.org/releases/avr-libc/avr-libc-user-manual-1.8.0.tar.bz2'
    sha1 '54f991e63c46eb430986bea3bae0e28cbe0b87c8'
  end

  def install
    binutils = Formula.factory('avr-binutils')
    args = [
            "--target=avr",
            "--disable-libssp",
            "--disable-nls",
            "--with-dwarf2",
            # Sandbox everything...
            "--prefix=#{prefix}",
            "--with-gmp=#{Formula.factory('gmp').opt_prefix}",
            "--with-mpfr=#{Formula.factory('mpfr').opt_prefix}",
            "--with-mpc=#{Formula.factory('libmpc').opt_prefix}",
            # ...except the stuff in share...
            "--datarootdir=#{share}",
            # ...and the binaries...
            "--bindir=#{bin}",
            # This shouldn't be necessary
            "--with-as=#{binutils.bin}/avr-as",
            "--with-ld=#{binutils.bin}/avr-ld"
           ]

    # The C compiler is always built, C++ can be disabled
    languages = %w[c]
    languages << 'c++' if build.with? 'cxx'

    mkdir 'build' do
      system '../configure', "--enable-languages=#{languages.join(',')}", *args
      system 'make'

      # At this point `make check` could be invoked to run the testsuite. The
      # deja-gnu and autogen formulae must be installed in order to do this.

      system 'make', 'install'

      multios = %x[gcc --print-multi-os-directory].strip

      # binutils already has a libiberty.a. We remove ours, because
      # otherwise, the symlinking of the keg fails
      File.unlink "#{prefix}/lib/#{multios}/libiberty.a"
    end

    ENV['CC'] = bin/'avr-gcc'
    resource('avr-libc').stage do
      system "./configure",
            "--build=#{%x[./config.guess].strip}",
            "--prefix=#{prefix}",
            "--host=avr"
      system 'make', 'install'
      prefix.install prefix/'avr/include', prefix/'avr/lib'
      rm_r prefix/'avr'
    end

    man.install resource('avr-libc-manpages')
    (share/'doc/avr-libc').install resource('avr-libc-html')
  end
end
