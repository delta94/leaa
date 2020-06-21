import React from 'react';
// @ts-ignore
import NProgress from 'nprogress';

export const Spinner = () => {
  React.useEffect(() => {
    NProgress.set(0.1);
    NProgress.start();

    return () => {
      NProgress.done();
      NProgress.remove();
    };
  }, []);

  return null;
  // return <Spin className={style['suspense-fallback-loader']} />;
};