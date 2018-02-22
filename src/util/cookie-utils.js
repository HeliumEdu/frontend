import Cookies from "universal-cookie";

const cookies = new Cookies();

export const setCookie = (name, value, options = {}) =>
    cookies.set(name, value, Object.assign({
        path: '/',
        maxAge: 604800,
        secure: process.env.REACT_APP_ENV === 'prod'
    }, options));

export const getCookie = (name, options = {}) =>
    cookies.get(name, Object.assign({
        path: '/'
    }, options));

export const deleteCookie = (name, options = {}) =>
    cookies.remove(name, Object.assign({
        path: '/'
    }, options));
