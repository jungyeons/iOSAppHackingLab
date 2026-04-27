'use strict';

function safeString(value) {
  try {
    return ObjC.Object(value).toString();
  } catch (_) {
    return '<unreadable>';
  }
}

function redact(value) {
  if (!value || value === '<unreadable>') {
    return value;
  }

  return '<redacted:' + value.length + '-chars>';
}

function attachSelector(className, selector, describeArgs) {
  const klass = ObjC.classes[className];
  if (!klass || !klass[selector]) {
    console.log('[lab] missing selector ' + className + ' ' + selector);
    return;
  }

  Interceptor.attach(klass[selector].implementation, {
    onEnter(args) {
      const details = describeArgs(args);
      console.log('[lab] ' + className + ' ' + selector + ' ' + details);
    }
  });
}

if (!ObjC.available) {
  console.log('[lab] Objective-C runtime is not available.');
} else {
  console.log('[lab] Observing iOSAppHackingLab probe only. No return values are modified.');

  attachSelector('LabObservationProbe', '- startObservationWithAccount:token:', function (args) {
    const account = safeString(args[2]);
    const token = safeString(args[3]);
    return 'accountLength=' + account.length + ' token=' + redact(token);
  });

  attachSelector('LabObservationProbe', '- recordCheckpointWithLabel:secret:', function (args) {
    const label = safeString(args[2]);
    const secret = safeString(args[3]);
    return 'label=' + label + ' secret=' + redact(secret);
  });

  attachSelector('LabObservationProbe', '- finishObservationWithResult:', function (args) {
    const result = safeString(args[2]);
    return 'result=' + result;
  });
}
