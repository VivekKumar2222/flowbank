import jwt from 'jsonwebtoken';

//generate Access token

const generateAccessToken  = (user)=>{
    return jwt.sign(
        {
            id: user._id,
            role: user.role,
        },
        process.env.JWT_SECRET,
        {expiresIn: '30m'}
    );
}

// Generate Refresh Token (long-lived)
const generateRefreshToken = (user) => {
    return jwt.sign(
        { id: user._id },
        process.env.JWT_SECRET,
        { expiresIn: '7d' } 
    );
};

export {generateAccessToken,generateRefreshToken};