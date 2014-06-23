var ENVIRONMENT = 'release';

var gulp = require('gulp');
var fs = require('fs');
var walk = require('walk').walk;
var exec = require('child_process').execFile;
var path = require('path');
var wrench = require('wrench');
var merge = require('merge-stream');
var svg2png = require('gulp-svg2png');

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

if (config.path.transcc === '') {
  config.path.transcc = './bin';
}

var transcc = config.path.transcc + '/transcc_' + host;
var qmake = config.path.qt + '/qmake';
var make = config.path.mingw + '/mingw32-make';
var bin = './bin';
var makedocs = bin + '/makedocs_' + host;

if (process.platform == 'win32') {
  transcc += '.exe';
  qmake += '.exe';
  make += '.exe';
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

var buildMonkeyProject = function(projectName, projectDestName, target) {
  var src = './src/' + projectName;
  var buildDir = path.resolve(src, '.build');

  if (!projectDestName) {
    projectDestName = projectName;
  }

  var transArgs = environment.transcc.args;

  if (target) {
    transArgs = environment.transcc.args.concat(['-target=' + target]);
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

        if (!fs.existsSync(tmp)) {
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
        fs.createReadStream(path.resolve(config.path.qt, dep)).pipe(fs.createWriteStream(path.resolve(bin, dep)));
      });
    } else {
      var dest = path.resolve(bin, path.basename(item));

      if (fs.existsSync(dest)) {
        wrench.rmdirSyncRecursive(dest);
      }

      wrench.copyDirRecursive(
        path.resolve(config.path.qt, item),
        dest,
        {forceDelete: false},
        callback
      );
    }
  });
});

gulp.task('docs', environment.options.build === 'clean' ? ['transcc', 'makedocs'] : [],
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
        callback(err);
      });
    });
  }
);

gulp.task('transcc', buildMonkeyProject('transcc', 'transcc_' + host));
gulp.task('makedocs', environment.options.build === 'clean' ? ['transcc'] : [], buildMonkeyProject('makedocs', 'makedocs_' + host));
gulp.task('mungo', environment.options.build === 'clean' ? ['transcc'] : [], buildMonkeyProject('mungo', '../mungo', 'Desktop_Game'));
gulp.task('mserver', buildQtProject('mserver', 'mserver_' + host));
gulp.task('jentos', buildQtProject('jentos'));

if (environment.options.build === 'clean') {
  gulp.task('default', ['dependencies', 'mserver', 'jentos', 'transcc', 'docs', 'mungo']);
} else {
  gulp.task('default', ['dependencies', 'mserver', 'jentos', 'docs', 'mungo']);
}


/*gulp.task('svg2png', function () {
 gulp.src('./src/resources/logo/*.svg')
 .pipe(svg2png())
 .pipe(gulp.dest('./.output/png'));
 });*/