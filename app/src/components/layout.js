import React from 'react';
import Header from './header';
import styles from './layout.module.sass';

const Layout = ({ children }) => {
  return (
    <>
      <Header />
      <div className={styles.contents}>{children}</div>
    </>
  );
};

export default Layout;
