/*

Copyright 2020 Convox, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

// Code generated by lister-gen. DO NOT EDIT.

package v1

import (
	v1 "github.com/convox/convox/pkg/atom/pkg/apis/atom/v1"
	"k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/labels"
	"k8s.io/client-go/tools/cache"
)

// AtomVersionLister helps list AtomVersions.
// All objects returned here must be treated as read-only.
type AtomVersionLister interface {
	// List lists all AtomVersions in the indexer.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1.AtomVersion, err error)
	// AtomVersions returns an object that can list and get AtomVersions.
	AtomVersions(namespace string) AtomVersionNamespaceLister
	AtomVersionListerExpansion
}

// atomVersionLister implements the AtomVersionLister interface.
type atomVersionLister struct {
	indexer cache.Indexer
}

// NewAtomVersionLister returns a new AtomVersionLister.
func NewAtomVersionLister(indexer cache.Indexer) AtomVersionLister {
	return &atomVersionLister{indexer: indexer}
}

// List lists all AtomVersions in the indexer.
func (s *atomVersionLister) List(selector labels.Selector) (ret []*v1.AtomVersion, err error) {
	err = cache.ListAll(s.indexer, selector, func(m interface{}) {
		ret = append(ret, m.(*v1.AtomVersion))
	})
	return ret, err
}

// AtomVersions returns an object that can list and get AtomVersions.
func (s *atomVersionLister) AtomVersions(namespace string) AtomVersionNamespaceLister {
	return atomVersionNamespaceLister{indexer: s.indexer, namespace: namespace}
}

// AtomVersionNamespaceLister helps list and get AtomVersions.
// All objects returned here must be treated as read-only.
type AtomVersionNamespaceLister interface {
	// List lists all AtomVersions in the indexer for a given namespace.
	// Objects returned here must be treated as read-only.
	List(selector labels.Selector) (ret []*v1.AtomVersion, err error)
	// Get retrieves the AtomVersion from the indexer for a given namespace and name.
	// Objects returned here must be treated as read-only.
	Get(name string) (*v1.AtomVersion, error)
	AtomVersionNamespaceListerExpansion
}

// atomVersionNamespaceLister implements the AtomVersionNamespaceLister
// interface.
type atomVersionNamespaceLister struct {
	indexer   cache.Indexer
	namespace string
}

// List lists all AtomVersions in the indexer for a given namespace.
func (s atomVersionNamespaceLister) List(selector labels.Selector) (ret []*v1.AtomVersion, err error) {
	err = cache.ListAllByNamespace(s.indexer, s.namespace, selector, func(m interface{}) {
		ret = append(ret, m.(*v1.AtomVersion))
	})
	return ret, err
}

// Get retrieves the AtomVersion from the indexer for a given namespace and name.
func (s atomVersionNamespaceLister) Get(name string) (*v1.AtomVersion, error) {
	obj, exists, err := s.indexer.GetByKey(s.namespace + "/" + name)
	if err != nil {
		return nil, err
	}
	if !exists {
		return nil, errors.NewNotFound(v1.Resource("atomversion"), name)
	}
	return obj.(*v1.AtomVersion), nil
}
