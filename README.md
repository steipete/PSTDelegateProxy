PSTDelegateProxy
================

A simple proxy that forwards optional methods to delegates - less boilerplate in your code!

When calling optional delegates, the regular pattern is to check using respondsToSelector:, then actually call the method. This is straightforward and easy to understand:


``` objective-c
    id<PSPDFResizableViewDelegate> delegate = self.delegate;
    if ([delegate respondsToSelector:@selector(resizableViewDidBeginEditing:)]) {
        [delegate resizableViewDidBeginEditing:self];
    }
```

What we really want is something like this:

``` objective-c
    [self.delegateProxy resizableViewDidBeginEditing:self];
```

Read more on my blog: [http://petersteinberger.com](http://petersteinberger.com)


License
=======
MIT License.