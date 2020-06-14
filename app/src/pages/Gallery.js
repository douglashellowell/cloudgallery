import React, {useEffect, useState} from 'react';
import {Link} from '@reach/router'
import {fetchImages} from '../utils/aws'

const Gallery = () => {
    const [images, setImages] = useState([])
    const [isLoading, setIsLoading] = useState(true)

    useEffect(fetchImages,[])

    return (
        <div>
            <h3>Gallery</h3>
            {isLoading && <p>loading...</p>}
            <Link to="/">Home</Link>
        </div>
    );
};





export default Gallery;