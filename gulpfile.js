var VERSION = '1.0.0-rc.2';
var ENVIRONMENT = 'release';

var gulp = require('gulp');
var fs = require('fs');
var walk = require('walk').walk;
var exec = require('child_process').execFile;
var path = require('path');
var wrench = require('wrench');
var merge = require('merge-stream');
var zip = require('gulp-zip');

var config = require('./buildconfig');
var environment = config.environment[ENVIRONMENT];
var options = environment.options;

var host = '';

if (process.platform == 'win32') {
  host = 'winnt';
} else if (process.platform == 'linux') {
  host = 'linux';
} else {
  host = 'macos';
}

if (environment.transcc.config !== '') {
  environment.transcc.args.push('-cfgfile=config.' + environment.transcc.config + '.' + host + '.txt');
}

if (config.path.monkey === '') {
  config.path.monkey = '.';
}

var transcc = config.path.monkey + '/bin/transcc_' + host;
var qmake = config.path.qt + '/bin/qmake';
var make = 'make';
var bin = './bin';
var makedocs = bin + '/makedocs_' + host;

if (process.platform == 'win32') {
  transcc += '.exe';
  qmake += '.exe';
  make = config.path.mingw + '/bin/mingw32-make.exe';
  makedocs += '.exe';
}

var buildQtProject = function(projectName, projectDestName) {
  var src = './src/' + projectName;
  var buildDir = path.resolve(src, '.build');

  if (!projectDestName) {
    projectDestName = projectName;
  }

  return function(callback) {
    if (!fs.existsSync(buildDir)) {
      fs.mkdirSync(buildDir);
    } else {
      wrench.rmdirSyncRecursive(buildDir);
      fs.mkdirSync(buildDir);
    }

    exec(
      qmake,
      environment.qmake.args.concat(path.resolve(src, projectName + '.pro')),
      {
        cwd: buildDir
      },

      function(err, stdout, stderr) {
        console.log(stdout);
        console.log(stderr);

        if (err) {
          callback(err);
          return;
        }

        exec(make, {cwd: buildDir},
          function(err, stdout, stderr) {
            console.log(stdout);
            console.log(stderr);

            var origin = projectName;
            var dest = projectDestName;

            if (process.platform == 'win32') {
              origin += '.exe';
              dest += '.exe';
            }

            var tmp = path.resolve(buildDir, 'release', origin);

            if (!fs.existsSync(tmp)) {
              tmp = path.resolve(buildDir, 'debug', origin);
            }

            if (!fs.existsSync(tmp)) {
              callback(err);
              return;
            }

            fs.renameSync(
              tmp,
              path.resolve(bin, dest)
            );

            callback(err);
          }
        );
      }
    );
  }
};

var buildMonkeyProject = function(projectName, projectDestName, target, extraTransArgs) {
  var src = './src/' + projectName;
  var buildDir = path.resolve(src, '.build');

  if (!projectDestName) {
    projectDestName = projectName;
  }

  var transArgs = environment.transcc.args;

  if (target) {
    transArgs = environment.transcc.args.concat(['-target=' + target]);
  }

  if (extraTransArgs) {
    transArgs = transArgs.concat(extraTransArgs);
  }

  return function(callback) {
    if (fs.existsSync(buildDir)) {
      wrench.rmdirSyncRecursive(buildDir);
    }

    return exec(
      transcc,
      transArgs.concat(["-builddir=.build", path.resolve(src, projectName + '.monkey')]),

      function(err, stdout, stderr) {
        console.log(stdout);
        console.log(stderr);

        if (err) {
          callback(err);
          return;
        }

        var origin = 'main_' + host;
        var dest = projectDestName;

        if (process.platform == 'win32') {
          origin += '.exe';
          dest += '.exe';
        }

        var tmp = path.resolve(src, '.build/cpptool', origin);

        if (target == 'Java_Tool') {
          tmp = path.resolve(src, '.build/javatool', 'main.jar');
        } else if (!fs.existsSync(tmp)) {
          tmp = path.resolve(src, '.build/glfw');

          if (fs.existsSync(tmp)) {
            origin = 'MonkeyGame' + path.extname(origin);

            if (process.platform == 'win32') {
              tmp = path.resolve(tmp, 'gcc_winnt');
            } else if (process.platform == 'linux') {
              tmp = path.resolve(tmp, 'gcc_linux');
            } else {
              tmp = path.resolve(tmp, 'xcode');
            }

            tmp = path.resolve(tmp, 'Release', origin);

            if (!fs.existsSync(tmp)) {
              tmp = path.resolve(buildDir, 'Debug', origin);
            }
          }
        }

        fs.renameSync(
          tmp,
          path.resolve(bin, dest)
        );

        callback(err);
      }
    );
  }
};

gulp.task('dependencies', function(callback) {
  environment.qt.dependencies.forEach(function(item) {
    if (Array.isArray(item)) {
      item.forEach(function(dep) {
        fs.createReadStream(path.resolve(config.path.qt, dep))
          .pipe(fs.createWriteStream(path.resolve(bin, path.basename(dep))));
      });
    } else {
      var dest = path.resolve(bin, path.basename(item));

      if (fs.existsSync(dest)) {
        wrench.rmdirSyncRecursive(dest);
      }

      wrench.copyDirSyncRecursive(
        path.resolve(config.path.qt, item),
        dest,
        {
          forceDelete: false,
          whitelist: true,
          filter: function (file) {
            return file.indexOf('d.dll') < 0;
          }
        }
      );
    }
  });

  callback();
});

gulp.task('docs', environment.options.build === 'clean' ? ['templates', 'transcc', 'makedocs'] : [],
  function(callback) {
    return exec(makedocs, function(err, stdout, stderr) {
      console.log(stdout);
      console.log(stderr);

      if (err) {
        callback(err);
        return;
      }

      var walker = walk('./docs/html/data');
      walker.on('file', function(root, fileStats, next) {
        if (path.extname(fileStats.name) == '.monkey') {
          var basename = path.basename(fileStats.name, '.monkey');

          if (path.basename(root) == basename) {
            exec(transcc,
              ['-config=release', '-target=Html5_Game', '-builddir='+basename+'.build', path.resolve(root, fileStats.name)],
              function(err, stdout, stderr) {
                console.log(stdout);
                console.log(stderr);

                next();
              }
            );
          } else {
            next();
          }
        } else {
          next();
        }
      });

      walker.on('end', function() {
        callback();
      });
    });
  }
);

gulp.task('templates', function(callback) {
  var walker = walk('./docs/templates');

  walker.on('file', function(root, fileStats, next) {
    if (fileStats.name == 'bower.json') {
      var bower = 'bower';
      var command = 'install';

      if (fs.existsSync(path.resolve(root, 'bower_components'))) {
        command = 'update';
      }

      if (process.platform == 'win32') {
        bower += '.cmd';
      }

      exec(bower, [command], {cwd: root}, function(err, stdout, stderr) {
        console.log(stdout);
        console.log(stderr);

        next();
      });
    } else {
      next();
    }

  });

  walker.on('end', function() {
    var walker = walk('./docs/templates');

    walker.on('file', function(root, fileStats, next) {
      if (fileStats.name == 'pagestyle.less') {
        var lessc = 'lessc';

        if (process.platform == 'win32') {
          lessc += '.cmd';
        }

        exec(lessc, [fileStats.name, 'pagestyle.css'], {cwd: root}, function(err, stdout, stderr) {
          console.log(stdout);
          console.log(stderr);

          next();
        });
      } else {
        next();
      }
    });

    walker.on('end', function() {
      callback();
    });
  });
});

gulp.task('dist', environment.options.build === 'clean' ? ['default'] : [], function() {
  var dest = './.output/build-' + process.platform;

  if (fs.existsSync(dest)) {
    wrench.rmdirSyncRecursive(dest);
  }

  wrench.copyDirSyncRecursive(
    '.',
    dest,
    {
      forceDelete: false,
      whitelist: true,
      filter: function(file, path) {
        var found;

        if (file === 'gulpfile.js' || file === 'package.json' || file === 'bower.json' || file === 'settings.ini' || file === 'junglembc2.exe') {
          return false;
        } else if (file === 'node_modules' || file === 'bower_components' || file === 'closure' || file === 'harmony') {
          return false;
        } else if (file.indexOf('.') === 0) {
          return false;
        } else if (file.indexOf('.build') > 0) {
          return path.indexOf('html') >= 0;
        } else if (file.indexOf('buildconfig') === 0 || file.indexOf('config.develop') === 0) {
          return false;
        } else if ((file.indexOf('mserver') === 0 || file.indexOf('jentos') === 0) && file.match(/.+\.(pro\.user|user)/)) {
          return false;
        } else if (file === 'less' || file.match(/.+\.less/i)) {
          return false;
        } else if (found = file.match(/mojo\.(.+)\.(js|as|cpp|cs|java)/i)) {
          if (found[1] !== 'html5' && found[1] !== 'html5.webgl'  && found[1] !== 'glfw') {
            return false;
          }
        } else if (found = file.match(/asyncimageloader\.(js|as|cpp|cs|java)/i)) {
          if (found[1] !== 'js') {
            return false;
          }
        } else if (found = file.match(/asyncsoundloader\.(js|as|cpp|cs|java)/i)) {
          if (found[1] !== 'js') {
            return false;
          }
        }

        return true
      }
    }
  );

  return gulp.src(dest + '/**/*')
    .pipe(zip('mungo-' + 'v' + VERSION + '-' + process.platform + '.zip'))
    .pipe(gulp.dest('./.output'));
});

gulp.task('transcc', buildMonkeyProject('transcc', 'transcc_' + host));
gulp.task('transcc_java', buildMonkeyProject('transcc', 'transcc_java.jar', 'Java_Tool', ['+JAVATOOL_STRING_PARSE_STYLE=cpp']));
gulp.task('makedocs', environment.options.build === 'clean' ? ['transcc'] : [], buildMonkeyProject('makedocs', 'makedocs_' + host));
gulp.task('mungo', environment.options.build === 'clean' ? ['transcc'] : [], buildMonkeyProject('mungo', '../mungo', 'Desktop_Game_(Glfw2)'));
gulp.task('mserver', buildQtProject('mserver', 'mserver_' + host));
gulp.task('jentos', buildQtProject('jentos'));

if (environment.options.build === 'clean') {
  gulp.task('default', ['dependencies', 'templates', 'mserver', 'jentos', 'transcc', 'docs', 'mungo']);
} else {
  gulp.task('default', ['dependencies', 'mserver', 'jentos', 'docs', 'mungo']);
}