import React from 'react';
import './App.scss';
import Layout from '../components/layout';
import {Router} from '@reach/router'
import PageNotFound from './PageNotFound';
import Home from './Home';
import Gallery from './Gallery';

function App() {
  return (
    <Layout>
      <Router >
        <Home path="/"/>
        <Gallery path="/gallery" />
        <PageNotFound default/>
      </Router>
    </Layout>
  );
}

export default App;
