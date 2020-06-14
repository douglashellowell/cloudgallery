import React from 'react';
import {Link} from '@reach/router'
import styles from './Home.module.sass';


const Home = () => {
    return (
        <div className={styles.home_container}>
          <h3 className={styles.welcome_message}>Welcome</h3>  
          <Link to="/gallery">Go to Gallery...</Link>
        </div>
    );
};

export default Home;